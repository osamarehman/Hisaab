require "test_helper"

class BankAlertTest < ActiveSupport::TestCase
  setup do
    @family = families(:dylan_family)
    @account = accounts(:depository)
    @parsed = BankAlert::Parser::Parsed.new(
      parser: "meezan", amount: BigDecimal("2500"), currency: "USD", direction: "out",
      last4: "9483", occurred_at: Time.zone.parse("2026-11-02 10:00"), payee: "O.REHMAN"
    )
  end

  test "approving a pending alert posts its transaction" do
    @account.update!(number_last4: "9483")
    alert = new_alert.tap { |a| a.file!(@parsed) }
    category = categories(:food_and_drink)

    alert.approve!(category: category, name: "Rent to O.Rehman")

    assert_equal "approved", alert.status
    txn = alert.entry.reload.transaction
    assert_not txn.pending?
    assert_equal category, txn.category
    assert_equal "Rent to O.Rehman", alert.entry.name
  end

  test "approving an alert with no account posts it there and remembers the digits" do
    alert = new_alert.tap { |a| a.file!(@parsed) }
    assert_equal "needs_account", alert.status

    assert_raises(BankAlert::InvalidTransition) { alert.approve! }
    alert.approve!(account: @account)

    assert_equal "approved", alert.status
    assert_equal @account, alert.entry.account
    assert_not alert.entry.transaction.pending?
    assert_equal "9483", @account.reload.number_last4
  end

  test "money in is a negative amount" do
    @account.update!(number_last4: "9483")
    alert = new_alert.tap { |a| a.file!(@parsed.with(direction: "in")) }
    assert_equal BigDecimal("-2500"), alert.entry.amount
  end

  test "rejecting deletes the pending transaction, and finished alerts can't change" do
    @account.update!(number_last4: "9483")
    alert = new_alert.tap { |a| a.file!(@parsed) }
    entry = alert.entry

    alert.reject!

    assert_equal "rejected", alert.status
    assert_not Entry.exists?(entry.id)
    assert_raises(BankAlert::InvalidTransition) { alert.approve!(account: @account) }
    assert_raises(BankAlert::InvalidTransition) { alert.reject! }
  end

  test "two accounts with the same digits leave the choice to the user" do
    @account.update!(number_last4: "9483")
    accounts(:credit_card).update!(number_last4: "9483")

    alert = new_alert.tap { |a| a.file!(@parsed) }
    assert_equal "needs_account", alert.status
  end

  private
    def new_alert
      @family.bank_alerts.new(message_id: SecureRandom.hex, received_at: Time.current, from_address: "no-reply@meezanbank.com", subject: "Alert")
    end
end
