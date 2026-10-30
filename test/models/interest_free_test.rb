require "test_helper"

# The interest-free switch end to end: loan calculations at an effective 0%.
# Each behaviour is checked with the switch on (the default) and off.
class InterestFreeTest < ActiveSupport::TestCase
  setup do
    @family = families(:empty)
    @today = Date.new(2027, 1, 15)
  end

  test "is on by default" do
    assert InterestFree.enabled?
  end

  test "an interest-free loan repays principal only, whatever its recorded rate" do
    loan = build_loan(interest_rate: 6, rate_type: "fixed", term_months: 24, principal: 24_000)
    schedule = loan.amortization_schedule

    assert_equal 24, schedule.payments.size
    assert schedule.payments.all? { |payment| payment.interest.zero? }
    assert_equal Money.new(1_000, "USD"), schedule.periodic_payment
    assert_equal Money.new(1_000, "USD"), loan.monthly_payment
    assert_equal Money.new(0, "USD"), schedule.total_interest
    assert_equal Money.new(24_000, "USD"), loan.total_cost
    assert_equal Money.new(23_000, "USD"), loan.remaining_balance_at(1)
    assert_equal Money.new(0, "USD"), loan.remaining_balance_at(24)

    breakdown = loan.payment_breakdown(payment_number: 3)
    assert_equal Money.new(0, "USD"), breakdown[:interest]
    assert_equal 1.0, breakdown[:ratios][:principal]
  end

  test "an interest-free loan needs no rate or rate type to have a schedule" do
    loan = build_loan(interest_rate: nil, rate_type: nil, term_months: 12, principal: 1_200)

    assert loan.amortizable?
    assert_equal Money.new(100, "USD"), loan.monthly_payment
    assert_equal Money.new(1_200, "USD"), loan.total_cost
  end

  test "recorded rate changes do not move an interest-free schedule" do
    loan = build_loan(interest_rate: 5, rate_type: "variable", term_months: 12, principal: 1_200)
    loan.update!(rate_changes: [ { effective_date: "2026-04-01", rate: "9" } ])

    schedule = loan.reload.amortization_schedule

    assert_not schedule.re_amortising?
    assert schedule.payments.all? { |payment| payment.payment == Money.new(100, "USD") }
    assert_equal 0, loan.current_variable_rate(@today)
  end

  test "an interest-free payoff projection finishes early on overpayment and saves no interest" do
    loan = build_loan(interest_rate: 6, rate_type: "fixed", term_months: 24, principal: 24_000)
    # Twelve payments in by @today, and 6,000 repaid beyond them.
    loan.account.update!(balance: 6_000)

    projection = loan.payoff_projection(as_of: @today)

    assert projection.converged?
    assert_equal 6, projection.months_saved
    assert_equal Money.new(0, "USD"), projection.total_interest
    assert_equal Money.new(0, "USD"), projection.interest_saved
  end

  test "the interest-free loan chart carries no interest split or saving" do
    loan = build_loan(interest_rate: 6, rate_type: "fixed", term_months: 24, principal: 24_000)
    loan.account.update!(balance: 6_000)

    chart = Loan::PayoffChart.new(loan, as_of: @today).payload

    assert_nil chart[:interest_saved]
    assert chart[:scheduled].none? { |point| point.key?(:interest) }
    assert_no_match(/interest/i, chart[:aria_description])
  end

  test "with interest-free off the loan charges its recorded rate as before" do
    InterestFree.stubs(:enabled?).returns(false)
    loan = build_loan(interest_rate: 6, rate_type: "fixed", term_months: 24, principal: 24_000)
    schedule = loan.amortization_schedule

    assert_operator schedule.total_interest.amount, :>, 0
    assert_operator loan.total_cost.amount, :>, 24_000
    assert_operator schedule.periodic_payment.amount, :>, 1_000
    assert_not build_loan(interest_rate: nil, rate_type: nil, term_months: 12, principal: 1_200).amortizable?
  end

  private
    def build_loan(interest_rate:, rate_type:, term_months:, principal:)
      account = @family.accounts.create!(
        name: "Loan #{SecureRandom.hex(4)}", balance: principal, currency: "USD",
        accountable: Loan.new(subtype: "other", interest_rate: interest_rate, rate_type: rate_type,
                              term_months: term_months, initial_balance: principal,
                              start_date: Date.new(2026, 1, 1))
      )
      account.entries.create!(date: Date.new(2026, 1, 1), name: "Opening balance", amount: principal,
                              currency: "USD", entryable: Valuation.new(kind: "opening_anchor"))
      account.loan
    end
end
