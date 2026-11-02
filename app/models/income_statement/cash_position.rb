# Cash on hand as of a date: cash and bank accounts minus credit card debt, in
# the family currency. A period's opening balance is the position the day before
# it starts and its closing balance the position on its last day, so one month's
# closing is the next month's opening.
#
# Reads each account's last synced balance on or before the date, so an account
# with no activity since an earlier day carries that balance forward.
class IncomeStatement::CashPosition
  ACCOUNTABLE_TYPES = %w[Depository CreditCard].freeze

  def initialize(family, accounts:)
    @family = family
    @accounts = accounts.visible.where(accountable_type: ACCOUNTABLE_TYPES)
  end

  # Returns nil when an account's balance can't be converted to the family
  # currency, rather than a total that silently leaves it out.
  def on(date)
    latest = Balance.where(account_id: @accounts.select(:id))
      .where(date: ..date)
      .select("DISTINCT ON (balances.account_id) balances.account_id, balances.end_balance, balances.currency")
      .order("balances.account_id, balances.date DESC")
    liability_ids = @accounts.liabilities.pluck(:id).to_set

    latest.sum(BigDecimal("0")) do |balance|
      amount = Money.new(balance.end_balance, balance.currency).exchange_to(@family.currency, date: date).amount
      liability_ids.include?(balance.account_id) ? -amount : amount
    end
  rescue Money::ConversionError
    nil
  end
end
