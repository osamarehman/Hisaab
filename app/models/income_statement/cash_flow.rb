# A bounded projection of Hisaab's existing reporting calculations for one period:
# a calendar month, or any range (last N months, all time, custom).
# The client never needs to download transaction history to reproduce these rules.
#
# Alongside income and spending it reads like a bank statement: the cash position
# the period opened and closed with, and `other_changes` for whatever moved that
# position without being income or spending (transfers to investment or loan
# accounts, balance edits, currency moves), so opening + income - spending +
# other_changes always equals closing.
class IncomeStatement::CashFlow
  # month: a calendar month, compared with the previous month up to the same day.
  # period: any range; compare: true compares it with the same-length range
  # just before it, false (e.g. all time) leaves the comparison null.
  def initialize(statement, month: nil, period: nil, compare: true, as_of: Date.current,
                 time_zone: Time.zone.tzinfo.identifier, include_sankey: false)
    if month
      raise ArgumentError, "month must be a non-future first day" unless month.day == 1 && month <= as_of
      period = Period.custom(start_date: month, end_date: [ month.end_of_month, as_of ].min)
    end
    raise ArgumentError, "a month or a period is required" unless period
    raise ArgumentError, "period must not end after as_of" if period.end_date > as_of

    @statement = statement
    @month = month
    @period = period
    @compare = compare
    @as_of = as_of
    @time_zone = time_zone
    @include_sankey = include_sankey
  end

  def as_json(*)
    totals = @statement.totals_for(@period)
    income = totals.income_money.amount
    spending = totals.expense_money.amount
    opening, closing = cash_position.on(@period.start_date - 1), cash_position.on(@period.end_date)

    result = {
      month: @month&.iso8601, as_of: @as_of.iso8601, time_zone: @time_zone,
      currency: @statement.family.currency,
      period: period_json(@period), income: decimal(income), spending: decimal(spending),
      net_savings: decimal(income - spending),
      savings_rate: income.positive? ? decimal((income - spending) / income * 100) : nil,
      opening_balance: opening && decimal(opening),
      closing_balance: closing && decimal(closing),
      other_changes: (opening && closing) ? decimal(closing - opening - income + spending) : nil,
      spending_by_category: spending_by_category,
      spending_comparison: spending_comparison
    }
    result[:sankey] = IncomeStatement::Sankey.new(@statement, period: @period).as_json if @include_sankey
    result
  end

  private
    def spending_comparison
      previous_period = comparison_period
      return nil unless previous_period

      current = cumulative_series(@period)
      previous = cumulative_series(previous_period)
      # A month in progress is compared with the same number of days of the
      # month before; any other range with the whole of the range before it.
      comparison_day = in_progress_month? ? [ @as_of.day, previous.size ].min : previous.size
      previous_total = previous.fetch(comparison_day - 1).fetch(:amount).to_d
      current_total = current.last.fetch(:amount).to_d

      {
        previous_period: period_json(previous_period),
        current_total: decimal(current_total), comparison_total: decimal(previous_total),
        comparison_end_date: previous.fetch(comparison_day - 1).fetch(:date),
        delta: decimal(current_total - previous_total), current: current, previous: previous
      }
    end

    def comparison_period
      if @month
        previous_month = @month.prev_month
        Period.custom(start_date: previous_month, end_date: previous_month.end_of_month)
      elsif @compare
        length = @period.days
        Period.custom(start_date: @period.start_date - length, end_date: @period.start_date - 1)
      end
    end

    def in_progress_month?
      @month && @month == @as_of.beginning_of_month
    end

    # Top-level categories only: a parent's total already includes its children.
    def spending_by_category
      @statement.expense_totals(period: @period).category_totals
        .select { |ct| ct.category.parent_id.nil? && !ct.total.zero? }
        .sort_by { |ct| -ct.total }
        .map do |ct|
          { category_id: ct.category.id, name: ct.category.name, color: ct.category.color, amount: decimal(ct.total) }
        end
    end

    def cash_position
      @cash_position ||= IncomeStatement::CashPosition.new(
        @statement.family,
        accounts: @statement.user ? @statement.user.finance_accounts : @statement.family.accounts
      )
    end

    def cumulative_series(period)
      daily = @statement.daily_expense_series(period: period).index_by(&:date)
      cumulative = BigDecimal("0")
      period.date_range.map do |date|
        cumulative += daily[date]&.total || 0
        { date: date.iso8601, amount: decimal(cumulative) }
      end
    end

    def period_json(period)
      { start_date: period.start_date.iso8601, end_date: period.end_date.iso8601 }
    end

    def decimal(value)
      value.to_d.to_s("F")
    end
end
