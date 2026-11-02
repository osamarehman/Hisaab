require "test_helper"

class BankAlert::Parsers::MeezanTest < ActiveSupport::TestCase
  DEBIT = <<~TEXT
    Dear Customer, PKR 10,000.00 sent from your account xxx9483 through Meezan Mobile.
    Beneficiary Account Title: : O.REHMAN  Branch : SADDAR BR HYD
    Transaction Date : 02-Nov-2026  Transaction Time : 18:05
    Disclaimer: amounts credited or received by mistake must be reported. Funds sent ...
  TEXT

  test "reads a debit alert" do
    parsed = parse(DEBIT)

    assert_equal "meezan", parsed.parser
    assert_equal BigDecimal("10000"), parsed.amount
    assert_equal "PKR", parsed.currency
    assert_equal "out", parsed.direction
    assert_equal "9483", parsed.last4
    assert_equal "O.REHMAN", parsed.payee
    assert_equal Time.find_zone("Asia/Karachi").parse("2026-11-02 18:05"), parsed.occurred_at
  end

  test "reads a credit alert by the verb next to the amount, not the disclaimer" do
    parsed = parse(<<~TEXT)
      PKR 2,500.50 received in your account xxx9483. Sender Account Title : AHMED KHAN Branch : CLIFTON
      Transaction Date : 01-Nov-2026 Disclaimer: funds sent or debited in error ...
    TEXT

    assert_equal "in", parsed.direction
    assert_equal BigDecimal("2500.5"), parsed.amount
    assert_equal "AHMED KHAN", parsed.payee
    assert_equal Date.new(2026, 11, 1), parsed.occurred_at.to_date
  end

  test "an email without an amount or direction is not an alert" do
    assert_nil parse("Your Meezan e-statement for October is ready.")
  end

  test "handles only Meezan's domain" do
    assert BankAlert::Parsers::Meezan.handles?("no-reply@meezanbank.com")
    assert_not BankAlert::Parsers::Meezan.handles?("no-reply@notmeezanbank.com")
  end

  private
    def parse(text)
      BankAlert::Parsers::Meezan.new(text: text, sent_at: Time.current, time_zone: "Asia/Karachi").parse
    end
end
