require "test_helper"

class BankAlertsMailboxTest < ActionMailbox::TestCase
  ALERT = "Dear Customer, PKR 10,000.00 sent from your account xxx9483 through Meezan Mobile. " \
          "Beneficiary Account Title: : O.REHMAN  Branch : SADDAR BR HYD " \
          "Transaction Date : 02-Nov-2026  Transaction Time : 18:05"

  setup do
    @family = families(:dylan_family)
    @family.update!(timezone: "Asia/Karachi")
    @inbox = @family.create_email_inbox!
    @family.email_senders.create!(pattern: "@meezanbank.com")
    @account = accounts(:depository)
    @account.update!(number_last4: "9483")
  end

  test "a Meezan alert on a known account becomes a pending transaction" do
    alert = deliver

    assert_equal "pending", alert.status
    assert_equal @account, alert.account
    entry = alert.entry
    assert_equal BigDecimal("10000"), entry.amount
    assert_equal Date.new(2026, 11, 2), entry.date
    assert_equal "O.REHMAN", entry.name
    assert entry.transaction.pending?, "stays out of balances and reports until approved"
  end

  test "an HTML, quoted-printable, Cp1252 alert is read like the real one" do
    html = "<html><body><table><tr><td>PKR 10,000.00 sent from your account xxx9483</td></tr>" \
           "<tr><td>Beneficiary Account Title: : O.REHMAN&nbsp; Branch : SADDAR BR HYD</td></tr>" \
           "<tr><td>Transaction Date : 02-Nov-2026 Transaction Time : 18:05</td></tr></table></body></html>"
    mail = Mail.new do
      from "Meezan Bank Alert <no-reply@meezanbank.com>"
      subject "Debit Transaction Alert"
      content_type "text/html; charset=Cp1252"
      content_transfer_encoding "quoted-printable"
      body html
    end
    mail.header["X-Original-To"] = @inbox.address
    mail.to = "me@gmail.com"

    alert = receive_inbound_email_from_source(mail.to_s) && @family.bank_alerts.last
    assert_equal "pending", alert.status
    assert_equal "O.REHMAN", alert.payee
  end

  test "no account with those digits leaves the alert waiting for one" do
    @account.update!(number_last4: nil)

    alert = deliver
    assert_equal "needs_account", alert.status
    assert_nil alert.entry
  end

  test "a sender the household hasn't allowed is kept unparsed and logged" do
    assert_difference -> { DebugLogEntry.count } do
      alert = deliver(from: "alerts@hbl.com")
      assert_equal "ignored", alert.status
      assert_nil alert.amount
    end
  end

  test "the same Message-ID twice files one alert" do
    # An identical copy is already dropped by Action Mailbox; a re-forward with
    # the same Message-ID but different headers or footer is not.
    deliver(message_id: "<same@meezanbank.com>")
    assert_no_difference -> { BankAlert.count } do
      deliver(message_id: "<same@meezanbank.com>", footer: "Forwarded again")
    end
  end

  test "mail to an unknown or rotated address files nothing" do
    old = @inbox.address
    @inbox.rotate!

    assert_no_difference -> { BankAlert.count } do
      deliver(to: old)
      deliver(to: "nobody@#{EmailInbox.domain}")
      deliver(to: "alerts@#{EmailInbox.domain}")
      deliver(to: "other+#{@inbox.token}@#{EmailInbox.domain}")
    end
  end

  test "Gmail's forwarding confirmation is stored for the app to show" do
    receive_inbound_email_from_mail(
      from: "Gmail Team <forwarding-noreply@google.com>", to: @inbox.address,
      subject: "(#123456789) Gmail Forwarding Confirmation - Receive Mail from me@gmail.com",
      body: "To allow forwarding, click https://mail-settings.google.com/mail/vf-abc123-xyz.\nConfirmation code: 123456789"
    )

    @inbox.reload
    assert_equal "123456789", @inbox.confirmation_code
    assert_equal "https://mail-settings.google.com/mail/vf-abc123-xyz", @inbox.confirmation_url
    assert_equal 0, @family.bank_alerts.count
  end

  private
    def deliver(from: "Meezan Bank Alert <no-reply@meezanbank.com>", to: @inbox.address, message_id: nil, footer: "")
      receive_inbound_email_from_mail(
        from: from, to: "me@gmail.com", "X-Original-To": to, subject: "Debit Transaction Alert",
        message_id: message_id || "<#{SecureRandom.hex(8)}@meezanbank.com>",
        body: "#{ALERT} #{footer}"
      )
      @family.bank_alerts.order(:created_at).last
    end
end
