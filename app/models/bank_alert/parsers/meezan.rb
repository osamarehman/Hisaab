# Meezan Bank's "Debit/Credit Transaction Alert" emails, e.g.
#   PKR 10,000.00 sent from your account xxx9483 ... Beneficiary Account
#   Title: : O.REHMAN Branch : SADDAR BR HYD Transaction Date : 02-Nov-2026
#   Transaction Time : 18:05
class BankAlert::Parsers::Meezan
  SENDER_DOMAIN = "@meezanbank.com".freeze
  AMOUNT = /\b(PKR|USD|EUR|GBP|AED|SAR)\s*([\d,]+(?:\.\d{1,2})?)/i
  OUT = /\b(?:sent|debited|withdrawn|paid|transferred)\b/i
  IN = /\b(?:received|credited|deposited)\b/i
  LAST4 = /\baccount\s+(?:no\.?\s*|number\s*)?[x*]+(\d{4})\b/i
  # A label's value runs until the next label; the email lays them out inline.
  LABELS = /\s+(?:Beneficiary|Sender|Remitter|Branch|Transaction Date|Transaction Time|Account|Bank|Reference|Channel)\b/i
  PAYEE = /\b(?:Beneficiary|Sender|Remitter)(?:\s+Account)?\s+(?:Title|Name)\s*:[\s:]*/i
  DATE = /Transaction Date\s*:\s*(\d{1,2}-[A-Za-z]{3}-\d{4})/i
  TIME = /Transaction Time\s*:\s*(\d{1,2}:\d{2})/i

  def self.handles?(from)
    from.to_s.downcase.end_with?(SENDER_DOMAIN)
  end

  def initialize(text:, sent_at:, time_zone:)
    @text = text.to_s.squish
    @sent_at = sent_at
    @time_zone = time_zone
  end

  def parse
    currency, amount = @text.match(AMOUNT)&.captures
    direction = direction_near_amount
    return nil unless amount && direction

    BankAlert::Parser::Parsed.new(
      parser: "meezan",
      amount: amount.delete(",").to_d,
      currency: currency.upcase,
      direction: direction,
      last4: @text[LAST4, 1],
      occurred_at: occurred_at,
      payee: payee
    )
  end

  private
    # The verb right after the amount says which way the money went; the
    # disclaimer further down mentions both.
    def direction_near_amount
      after_amount = @text[(@text =~ AMOUNT).to_i, 120].to_s
      out_at = after_amount =~ OUT
      in_at = after_amount =~ IN
      return nil unless out_at || in_at

      in_at.nil? || (out_at && out_at < in_at) ? "out" : "in"
    end

    def payee
      start = @text =~ PAYEE
      return nil unless start

      rest = @text[(start + @text[PAYEE].length)..]
      rest.split(LABELS, 2).first.to_s.strip.presence
    end

    def occurred_at
      date = @text[DATE, 1]
      return @sent_at unless date

      zone = ActiveSupport::TimeZone[@time_zone.to_s] || Time.zone
      zone.parse("#{date} #{@text[TIME, 1] || '00:00'}")
    rescue ArgumentError
      @sent_at
    end
end
