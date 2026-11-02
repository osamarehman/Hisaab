# Turns one inbound email into a BankAlert for the household whose private
# address it was sent to. Mail to an unknown address, or a Message-ID the
# household has already seen, is dropped; mail from a sender the household
# hasn't allowed is kept as `ignored` (unparsed) so the user can allow it.
class BankAlert::Receiver
  attr_reader :mail, :inbound_email

  def initialize(mail, inbound_email: nil)
    @mail = mail
    @inbound_email = inbound_email
  end

  # @return [BankAlert, nil] the alert filed, or nil when nothing was filed
  def call
    inbox = EmailInbox.for_recipients(recipients)
    return log_drop("No household inbox for recipients", recipients: recipients) unless inbox

    family = inbox.family
    if from == EmailInbox::GMAIL_CONFIRMATION_SENDER
      inbox.record_gmail_confirmation!(subject: mail.subject, body: text)
      return nil
    end

    return nil if family.bank_alerts.exists?(message_id: message_id)

    alert = family.bank_alerts.new(
      inbound_email: inbound_email, message_id: message_id, from_address: from,
      subject: mail.subject.to_s.truncate(255), received_at: mail.date || Time.current,
      sender_verified: sender_verified?
    )

    unless family.email_senders.any? { |sender| sender.matches?(from) }
      alert.update!(status: "ignored")
      log_drop("Bank alert from a sender the household hasn't allowed", family: family, from: from)
      return alert
    end

    parsed = BankAlert::Parser.parse(from: from, text: text, sent_at: mail.date)
    if parsed
      alert.file!(parsed)
    else
      alert.update!(status: "unparsed", error: I18n.t("bank_alerts.unparsed"))
    end
    alert
  rescue ActiveRecord::RecordNotUnique
    nil # the same message arrived twice at once
  end

  private
    # X-Original-To carries the envelope recipient: a forwarded alert keeps
    # the bank's To header, which names the user's own address, not ours.
    def recipients
      [ mail.header["X-Original-To"]&.value, *mail.to, *mail.cc ].compact.map { |address| address.to_s.downcase.strip }
    end

    def from
      @from ||= Array(mail.from).first.to_s.downcase.strip
    end

    def message_id
      @message_id ||= mail.message_id.presence || Digest::SHA256.hexdigest(mail.to_s)
    end

    # True when our mail server's DMARC check passed for the From domain, so
    # the bank itself sent it. Our milter adds its Authentication-Results above
    # the message's own headers, so only the topmost one with our authserv-id
    # counts; a sender's forged copy sits below it.
    # ponytail: trusts the topmost header, which only holds while every inbound
    # message runs through OpenDMARC (not for authenticated submissions).
    def sender_verified?
      authserv_id = ENV["BANK_ALERTS_AUTHSERV_ID"].presence or return false
      result = mail.header.fields
        .select { |field| field.name.casecmp?("Authentication-Results") }
        .map { |field| field.value.to_s.squish }
        .find { |value| value.start_with?("#{authserv_id};") && value.include?("dmarc=") }
      return false unless result

      result.match?(/\bdmarc=pass\b/) && result[/\bheader\.from=([^\s;]+)/, 1]&.downcase == from.split("@").last
    end

    # Plain text, falling back to the HTML part with its tags stripped.
    def text
      @text ||= begin
        part = mail.multipart? ? (mail.text_part || mail.html_part) : mail
        body = part&.decoded.to_s
        body = body.encode("UTF-8", invalid: :replace, undef: :replace) unless body.encoding == Encoding::UTF_8 && body.valid_encoding?
        html = part&.mime_type.to_s.include?("html") || body.match?(/<(?:html|body|div|td|p)\b/i)
        html ? Nokogiri::HTML(body.gsub(/<br\s*\/?>|<\/(?:p|div|tr|td)>/i, " \\0")).text : body
      end
    end

    def log_drop(message, family: nil, **metadata)
      DebugLogEntry.capture(
        category: "bank_alert_email", level: "info", message: message, source: self.class.name,
        provider_key: "email", family: family, metadata: metadata.merge(message_id: mail.message_id)
      )
      nil
    end
end
