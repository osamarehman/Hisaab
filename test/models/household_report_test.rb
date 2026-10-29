require "test_helper"

class HouseholdReportTest < ActiveSupport::TestCase
  include EntriesTestHelper

  setup do
    @family = families(:dylan_family)
    @user = users(:family_admin)
    @account = accounts(:depository)
    @food = categories(:food_and_drink)
    @restaurants = categories(:subcategory)
    @income = categories(:income)
    @start = Date.new(2020, 3, 1)
    @end = Date.new(2020, 4, 30)

    create_transaction(date: @start + 1, name: "Groceries", amount: 2500, category: @food)
    create_transaction(date: @start + 2, name: "Dinner out", amount: 1200, category: @restaurants)
    create_transaction(date: @start + 3, name: "Salary", amount: -50_000, category: @income)
    create_transaction(date: @start + 35, name: "Rickshaw", amount: 300)
  end

  test "reports money in and out per currency, skipping transfers and excluded rows" do
    create_transaction(date: @start + 4, name: "To savings", amount: 1000, kind: "funds_movement")
    create_transaction(date: @start + 5, name: "Split parent", amount: 999, excluded: true)
    create_transaction(date: @end + 1, name: "Next month", amount: 10)

    report = build_report

    assert_equal [ "Groceries", "Dinner out", "Salary", "Rickshaw" ], report.rows.map(&:name)
    total = report.totals.sole
    assert_equal "USD", total.currency
    assert_equal 50_000, total.money_in
    assert_equal 4000, total.money_out
    assert_equal 46_000, total.net
    assert_equal [ Date.new(2020, 3, 1), Date.new(2020, 4, 1) ], report.rows_by_month.keys
  end

  test "loan payments count as money out whatever their sign" do
    create_transaction(date: @start + 6, name: "Loan", amount: -700, kind: "loan_payment")

    assert_equal :out, build_report.rows.find { |r| r.name == "Loan" }.direction
  end

  test "label filter includes sublabels and optionally unlabelled rows" do
    report = build_report(categories: [ @food ])
    assert_equal [ "Groceries", "Dinner out" ], report.rows.map(&:name)

    report = build_report(categories: [ @food ], include_uncategorized: true)
    assert_equal [ "Groceries", "Dinner out", "Rickshaw" ], report.rows.map(&:name)

    report = build_report(categories: [], include_uncategorized: true)
    assert_equal [ "Rickshaw" ], report.rows.map(&:name)

    report = build_report(include_uncategorized: false)
    assert_equal [ "Groceries", "Dinner out", "Salary" ], report.rows.map(&:name)
  end

  test "account filter and account access limit the rows" do
    other = accounts(:credit_card)
    create_transaction(account: other, date: @start + 7, name: "Card", amount: 50)

    assert_equal [ "Card" ], build_report(accounts: [ other ]).rows.map(&:name)

    create_transaction(account: accounts(:other_asset), date: @start + 7, name: "Private", amount: 50)
    assert_includes build_report.rows.map(&:name), "Private"
    assert_not_includes build_report(user: users(:family_member)).rows.map(&:name), "Private"
  end

  test "label totals group by label and currency" do
    totals = build_report.label_totals

    food = totals.find { |t| t.category == @food }
    assert_equal 2500, food.money_out
    assert_equal 1, food.count
    assert_equal 300, totals.find { |t| t.category.nil? }.money_out
  end

  test "validates the period" do
    assert_not build_report(start_date: nil).valid?
    assert_not build_report(start_date: @end, end_date: @start).valid?
    assert_not build_report(end_date: @start.advance(months: 24)).valid?
    assert build_report(end_date: @start.advance(months: 24) - 1).valid?
  end

  test "refuses reports over the entry limit" do
    stub_const(HouseholdReport, :MAX_ENTRIES, 3) do
      report = build_report
      assert_not report.valid?
      assert_match "more than 3 entries", report.errors.full_messages.to_sentence
    end
  end

  test "renders a PDF with the summary and every entry" do
    create_transaction(date: @start + 8, name: "Euro gift", amount: -12.5, currency: "EUR")

    pdf = build_report(categories: [ @food ], include_uncategorized: true).to_pdf
    text = PDF::Reader.new(StringIO.new(pdf)).pages.map(&:text).join("\n")

    assert pdf.start_with?("%PDF")
    assert_includes text, "Hisaab report"
    assert_includes text, @family.name
    assert_includes text, "1 Mar 2020 – 30 Apr 2020"
    assert_includes text, "Food & Drink, Unlabelled"
    assert_includes text, "March 2020"
    assert_includes text, "Groceries"
    assert_includes text, "$2,500"
    assert_includes text, "€12.50"
    assert_includes text, "March subtotal"
  end

  test "formats PKR like the app" do
    @account.update!(currency: "PKR")
    create_transaction(date: @start + 9, name: "Doodh", amount: 2500, currency: "PKR")

    text = PDF::Reader.new(StringIO.new(build_report.to_pdf)).pages.map(&:text).join("\n")

    assert_includes text, "Rs 2,500"
  end

  private
    def build_report(**overrides)
      HouseholdReport.new(family: @family, user: @user, start_date: @start, end_date: @end, **overrides)
    end

    def stub_const(klass, name, value)
      original = klass.const_get(name)
      klass.send(:remove_const, name)
      klass.const_set(name, value)
      yield
    ensure
      klass.send(:remove_const, name)
      klass.const_set(name, original)
    end
end
