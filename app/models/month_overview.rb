# One month of household money for the dashboard header: what came in, what
# went out, where it went by label, and the latest activity. Figures come
# from IncomeStatement's netted category totals, the same numbers the
# outflows widget and budgets use, so refunds net against their label.
class MonthOverview
  RECENT_LIMIT = 8

  LabelRow = Data.define(:category, :amount, :share)

  attr_reader :family, :user, :month

  # A month after the current one is clamped to the current one: its period
  # would end before it starts.
  def self.month_from_param(value, today: Date.current)
    month = Date.strptime(value.to_s, "%Y-%m").beginning_of_month
    [ month, today.beginning_of_month ].min
  rescue ArgumentError, TypeError
    today.beginning_of_month
  end

  def initialize(family, user:, month:)
    @family = family
    @user = user
    @month = month.to_date.beginning_of_month
  end

  def current_month?
    month == Date.current.beginning_of_month
  end

  def spent
    money(net_totals.total_net_expense)
  end

  def came_in
    money(net_totals.total_net_income)
  end

  def left_over
    came_in - spent
  end

  # Share of income not spent, as a whole percentage; nil without income.
  def kept_percent
    return nil unless came_in.positive?

    (left_over.amount / came_in.amount * 100).round
  end

  # Positive when this month's spending is above last month's.
  def spent_change
    spent - money(statement.net_category_totals(period: period_for(month.prev_month)).total_net_expense)
  end

  def label_rows
    @label_rows ||= begin
      rows = net_totals.net_expense_categories.reject { |ct| ct.total.zero? }.sort_by { |ct| -ct.total }
      largest = rows.first&.total.to_f
      rows.map do |ct|
        LabelRow.new(
          category: ct.category,
          amount: money(ct.total),
          share: largest.zero? ? 0 : (ct.total.to_f / largest * 100).round
        )
      end
    end
  end

  def recent_entries
    @recent_entries ||= family.entries
      .where(account_id: user.accessible_accounts.select(:id), entryable_type: "Transaction")
      .where(date: period.date_range)
      .visible
      .excluding_split_parents
      .reverse_chronological
      .preload(:account, entryable: :category)
      .limit(RECENT_LIMIT)
      .to_a
  end

  def period
    @period ||= period_for(month)
  end

  private
    def statement
      @statement ||= family.income_statement
    end

    def net_totals
      @net_totals ||= statement.net_category_totals(period: period)
    end

    def period_for(start)
      Period.custom(start_date: start, end_date: [ start.end_of_month, Date.current ].min)
    end

    def money(amount)
      Money.new(amount, family.currency)
    end
end
