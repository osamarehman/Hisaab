require "test_helper"

class MonthOverviewTest < ActiveSupport::TestCase
  include EntriesTestHelper

  setup do
    @family = families(:empty)
    @user = users(:empty)
    @food = @family.categories.create!(name: "Food", color: "#121413")
    @bills = @family.categories.create!(name: "Bills", color: "#2445C8")
    @salary = @family.categories.create!(name: "Salary")
    @account = @family.accounts.create!(name: "Checking", currency: @family.currency, balance: 5000, accountable: Depository.new)
    @month = Date.current.beginning_of_month
  end

  test "month_from_param reads YYYY-MM and clamps future months to this one" do
    today = Date.new(2026, 10, 27)

    assert_equal Date.new(2026, 8, 1), MonthOverview.month_from_param("2026-08", today: today)
    assert_equal Date.new(2026, 10, 1), MonthOverview.month_from_param("2027-01", today: today)
    assert_equal Date.new(2026, 10, 1), MonthOverview.month_from_param("nonsense", today: today)
    assert_equal Date.new(2026, 10, 1), MonthOverview.month_from_param(nil, today: today)
  end

  test "totals and labels for the month, largest label first" do
    create_transaction(account: @account, amount: -1000, category: @salary, currency: @family.currency)
    create_transaction(account: @account, amount: 100, category: @food, currency: @family.currency)
    create_transaction(account: @account, amount: 300, category: @bills, currency: @family.currency)

    overview = MonthOverview.new(@family, user: @user, month: @month)

    assert_equal Money.new(400, @family.currency), overview.spent
    assert_equal Money.new(1000, @family.currency), overview.came_in
    assert_equal Money.new(600, @family.currency), overview.left_over
    assert_equal 60, overview.kept_percent
    assert_equal [ "Bills", "Food" ], overview.label_rows.map { |row| row.category.name }
    assert_equal [ 100, 33 ], overview.label_rows.map(&:share)
  end

  test "recent activity stays inside the month" do
    create_transaction(account: @account, amount: 50, name: "This month", date: @month, currency: @family.currency)
    create_transaction(account: @account, amount: 50, name: "Last month", date: @month.prev_month, currency: @family.currency)

    names = MonthOverview.new(@family, user: @user, month: @month).recent_entries.map(&:name)

    assert_includes names, "This month"
    assert_not_includes names, "Last month"
  end

  test "kept_percent is nil without income" do
    assert_nil MonthOverview.new(@family, user: @user, month: @month).kept_percent
  end

  test "range_from_params reads named ranges, all time and in-order custom dates" do
    today = Date.new(2026, 11, 2)
    travel_to today do
      three = MonthOverview.range_from_params({ range: "last_3_months" }, family: @family, today: today)
      assert_equal [ Date.new(2026, 9, 1), today ], [ three.start_date, three.end_date ]

      custom = MonthOverview.range_from_params({ range: "custom", from: "2026-10-01", to: "2027-01-01" }, family: @family, today: today)
      assert_equal [ Date.new(2026, 10, 1), today ], [ custom.start_date, custom.end_date ], "a future end is capped at today"
      assert_nil custom.key

      assert_equal "all_time", MonthOverview.range_from_params({ range: "all_time" }, family: @family, today: today).key
      assert_nil MonthOverview.range_from_params({ range: "custom", from: "2026-10-05", to: "2026-10-01" }, family: @family, today: today)
      assert_nil MonthOverview.range_from_params({ range: "custom", from: "nope" }, family: @family, today: today)
      assert_nil MonthOverview.range_from_params({ range: "last_90_days" }, family: @family, today: today)
      assert_nil MonthOverview.range_from_params({}, family: @family, today: today)
    end
  end

  test "a month opens with the previous month's closing balance" do
    @account.balances.create!(date: @month.prev_month.end_of_month, balance: 800, currency: @family.currency, start_cash_balance: 800)
    @account.balances.create!(date: @month, balance: 500, currency: @family.currency, start_cash_balance: 500)

    overview = MonthOverview.new(@family, user: @user, month: @month)
    previous = MonthOverview.new(@family, user: @user, month: @month.prev_month)

    assert_equal 800, overview.opening_balance.amount
    assert_equal previous.closing_balance, overview.opening_balance
    assert_equal 500, overview.closing_balance.amount
  end

  test "a range covers its whole period and compares with the same length before it" do
    travel_to Date.new(2026, 11, 2) do
      create_transaction(account: @account, amount: 100, category: @food, currency: @family.currency, date: Date.new(2026, 9, 3))
      create_transaction(account: @account, amount: 40, category: @food, currency: @family.currency, date: Date.new(2026, 7, 1))

      range = MonthOverview.range_from_params({ range: "last_3_months" }, family: @family)
      overview = MonthOverview.new(@family, user: @user, month: Date.current, range: range)

      assert overview.ranged?
      assert_equal 100, overview.spent.amount
      assert_equal Date.new(2026, 6, 30), overview.comparison_period.start_date
      assert_equal 60, overview.spent_change.amount

      all_time = MonthOverview.new(@family, user: @user, month: Date.current, range: MonthOverview.range_from_params({ range: "all_time" }, family: @family))
      assert_nil all_time.spent_change
    end
  end
end
