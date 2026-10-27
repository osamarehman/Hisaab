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
end
