require "test_helper"

class IncomeStatement::CashFlowTest < ActiveSupport::TestCase
  include EntriesTestHelper

  setup do
    @family = families(:empty)
    @account = @family.accounts.create! name: "Checking", currency: "USD", balance: 5000, accountable: Depository.new
    @month = Date.new(2024, 2, 1)
  end

  test "reads account and exchange rate freshness once for the complete report" do
    Rails.stubs(:cache).returns(ActiveSupport::Cache::MemoryStore.new)
    queries = ActiveRecord::Base.uncached { capture_sql_queries { summary } }

    assert_equal 1, queries.grep(/MAX\("accounts"\."updated_at"\)/i).size
    assert_equal 1, queries.grep(/MAX\("exchange_rates"\."updated_at"\)/i).size
  end

  test "uses server reporting rules and exact decimal amounts" do
    create_transaction(account: @account, amount: -1000, date: @month)
    create_transaction(account: @account, amount: 12.345.to_d, date: @month)
    create_transaction(account: @account, amount: -20, date: @month, kind: "loan_payment")
    create_transaction(account: @account, amount: 900, date: @month, kind: "cc_payment")
    create_transaction(account: @account, amount: 800, date: @month, excluded: true)
    pending = create_transaction(account: @account, amount: 700, date: @month)
    pending.entryable.update!(extra: { "simplefin" => { "pending" => true } })
    result = summary
    assert_equal "1000.0", result[:income]
    assert_equal "32.345", result[:spending]
    assert_equal "967.655", result[:net_savings]
    assert_equal "32.345", result[:spending_comparison][:current_total]
    assert_equal "96.7655", result[:savings_rate]
  end

  test "fills every day and compares current month to the same elapsed day" do
    create_transaction(account: @account, amount: 10, date: Date.new(2024, 1, 10))
    create_transaction(account: @account, amount: 90, date: Date.new(2024, 1, 31))
    result = summary(as_of: Date.new(2024, 2, 15))[:spending_comparison]
    assert_equal 15, result[:current].size
    assert_equal 31, result[:previous].size
    assert_equal "10.0", result[:comparison_total]
    assert_equal "100.0", result[:previous].last[:amount]
    assert_equal "2024-01-15", result[:comparison_end_date]
  end

  test "historical leap month retains full previous month and null rate without income" do
    result = summary
    assert_nil result[:savings_rate]
    assert_equal 29, result[:spending_comparison][:current].size
    assert_equal 31, result[:spending_comparison][:previous].size
    assert_equal "2024-01-31", result[:spending_comparison][:comparison_end_date]
  end

  test "rejects future and nonfirst month" do
    assert_raises(ArgumentError) { summary(month: Date.new(2025, 1, 1)) }
    assert_raises(ArgumentError) { summary(month: Date.new(2024, 2, 2)) }
  end

  test "does not include another family" do
    create_transaction(account: accounts(:depository), amount: 100, date: @month)
    assert_equal "0.0", summary[:spending]
  end

  test "reports FX-converted values without rounding to currency minor units" do
    eur = @family.accounts.create!(name: "EUR", currency: "EUR", balance: 0, accountable: Depository.new)
    ExchangeRate.create!(from_currency: "EUR", to_currency: "USD", date: @month, rate: "1.2345")
    create_transaction(account: eur, currency: "EUR", amount: 10, date: @month)
    assert_equal "12.345", summary[:spending]
    assert_equal "12.345", summary[:spending_comparison][:current_total]
  end

  test "savings rate may be negative and currency remains attached" do
    @family.update!(currency: "JPY")
    @account.update!(currency: "JPY")
    create_transaction(account: @account, currency: "JPY", amount: -100, date: @month)
    create_transaction(account: @account, currency: "JPY", amount: 150, date: @month)
    assert_equal "JPY", summary[:currency]
    assert_equal "-50.0", summary[:savings_rate]
  end

  test "a month opens with the previous month's closing balance" do
    set_balance(@account, Date.new(2024, 1, 31), 1000)
    create_transaction(account: @account, amount: -500, date: Date.new(2024, 2, 1))
    create_transaction(account: @account, amount: 200, date: Date.new(2024, 2, 10))
    set_balance(@account, Date.new(2024, 2, 10), 1300)

    january = summary(month: Date.new(2024, 1, 1))
    february = summary

    assert_equal "1000.0", january[:closing_balance]
    assert_equal january[:closing_balance], february[:opening_balance]
    assert_equal "1300.0", february[:closing_balance]
    assert_equal "0.0", february[:other_changes]
  end

  test "other changes reconcile moves that are neither income nor spending" do
    set_balance(@account, Date.new(2024, 1, 31), 1000)
    create_transaction(account: @account, amount: 100, date: Date.new(2024, 2, 5))
    # The balance also dropped by a 400 transfer that isn't spending.
    set_balance(@account, Date.new(2024, 2, 5), 500)

    result = summary
    assert_equal "-400.0", result[:other_changes]
    opening, closing = result[:opening_balance].to_d, result[:closing_balance].to_d
    assert_equal closing, opening + result[:income].to_d - result[:spending].to_d + result[:other_changes].to_d
  end

  test "credit card debt lowers the cash position and investments are left out" do
    card = @family.accounts.create!(name: "Card", currency: "USD", balance: 0, accountable: CreditCard.new)
    brokerage = @family.accounts.create!(name: "Brokerage", currency: "USD", balance: 0, accountable: Investment.new)
    set_balance(@account, Date.new(2024, 2, 29), 1000)
    set_balance(card, Date.new(2024, 2, 29), 300)
    set_balance(brokerage, Date.new(2024, 2, 29), 9000)

    assert_equal "700.0", summary[:closing_balance]
  end

  test "spending by category lists top-level categories, largest first" do
    parent = @family.categories.create!(name: "Home", color: "#111111")
    child = @family.categories.create!(name: "Repairs", color: "#222222", parent: parent)
    food = @family.categories.create!(name: "Food", color: "#333333")
    create_transaction(account: @account, amount: 30, date: @month, category: child)
    create_transaction(account: @account, amount: 20, date: @month, category: parent)
    create_transaction(account: @account, amount: 10, date: @month, category: food)

    rows = summary[:spending_by_category]
    assert_equal [ [ "Home", "50.0" ], [ "Food", "10.0" ] ], rows.map { |row| [ row[:name], row[:amount] ] }
    assert_equal parent.id, rows.first[:category_id]
  end

  test "a range compares with the same-length range before it, and all time with nothing" do
    create_transaction(account: @account, amount: 40, date: Date.new(2023, 12, 15))
    create_transaction(account: @account, amount: 25, date: Date.new(2024, 2, 15))
    range = Period.custom(start_date: Date.new(2024, 1, 1), end_date: Date.new(2024, 2, 29))
    statement = IncomeStatement.new(@family)

    result = IncomeStatement::CashFlow.new(statement, period: range, as_of: Date.new(2024, 3, 5)).as_json
    assert_nil result[:month]
    assert_equal({ start_date: "2023-11-02", end_date: "2023-12-31" }, result[:spending_comparison][:previous_period])
    assert_equal "40.0", result[:spending_comparison][:comparison_total]
    assert_equal "25.0", result[:spending]

    all_time = IncomeStatement::CashFlow.new(statement, period: range, compare: false, as_of: Date.new(2024, 3, 5)).as_json
    assert_nil all_time[:spending_comparison]
  end

  test "an unconvertible balance makes the statement unavailable rather than wrong" do
    eur = @family.accounts.create!(name: "EUR", currency: "EUR", balance: 0, accountable: Depository.new)
    set_balance(eur, Date.new(2024, 2, 29), 100)
    ExchangeRate.stubs(:find_or_fetch_rate).returns(nil)

    result = summary
    assert_nil result[:closing_balance]
    assert_nil result[:other_changes]
  end

  private
    def summary(month: @month, as_of: Date.new(2024, 3, 5))
      IncomeStatement::CashFlow.new(IncomeStatement.new(@family), month: month, as_of: as_of).as_json
    end

    def set_balance(account, date, amount)
      account.balances.create!(date: date, balance: amount, currency: account.currency, start_cash_balance: amount)
    end
end
