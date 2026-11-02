# One month of household money for the dashboard header: what came in, what
# went out, where it went by label, and the latest activity. Figures come
# from IncomeStatement's netted category totals, the same numbers the
# outflows widget and budgets use, so refunds net against their label.
#
# A `range` (last 3/6/12 months, all time or custom dates) replaces the month
# with any period. Either way the header also shows the cash position the
# period opened and closed with, so money left over carries into the next.
class MonthOverview
  RECENT_LIMIT = 8
  RANGE_KEYS = %w[last_3_months last_6_months last_12_months all_time].freeze

  LabelRow = Data.define(:category, :amount, :share)

  attr_reader :family, :user, :month, :range

  # A month after the current one is clamped to the current one: its period
  # would end before it starts.
  def self.month_from_param(value, today: Date.current)
    month = Date.strptime(value.to_s, "%Y-%m").beginning_of_month
    [ month, today.beginning_of_month ].min
  rescue ArgumentError, TypeError
    today.beginning_of_month
  end

  # ?range=<key>, or ?range=custom&from=YYYY-MM-DD&to=YYYY-MM-DD. Nil (the
  # month view) for anything else, including a custom range out of order.
  def self.range_from_params(params, family:, today: Date.current)
    case params[:range]
    when "all_time"
      # From the oldest entry, opening balances included, so it opens at zero.
      Period.new(key: "all_time", start_date: [ family.oldest_entry_date, today ].min, end_date: today)
    when *RANGE_KEYS
      Period.from_key(params[:range])
    when "custom"
      from = Date.iso8601(params[:from].to_s)
      to = [ Date.iso8601(params[:to].to_s), today ].min
      Period.custom(start_date: from, end_date: to) if from <= to
    end
  rescue Date::Error
    nil
  end

  def initialize(family, user:, month:, range: nil)
    @family = family
    @user = user
    @month = month.to_date.beginning_of_month
    @range = range
  end

  def ranged?
    range.present?
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

  # Positive when spending is above the comparison period's: last month for
  # a month, the same length of time before a range. Nil for all time.
  def spent_change
    return nil unless comparison_period

    spent - money(statement.net_category_totals(period: comparison_period).total_net_expense)
  end

  def comparison_period
    return Period.custom(start_date: month.prev_month, end_date: month.prev_month.end_of_month) unless ranged?
    return nil if range.key == "all_time"

    Period.custom(start_date: period.start_date - period.days, end_date: period.start_date - 1)
  end

  # Cash and bank accounts minus credit card debt the day before the period,
  # and on its last day. Nil when a balance can't be converted.
  def opening_balance
    cash_money(cash_position.on(period.start_date - 1))
  end

  def closing_balance
    cash_money(cash_position.on(period.end_date))
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
    @period ||= range || period_for(month)
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

    def cash_money(amount)
      amount && money(amount)
    end

    def cash_position
      @cash_position ||= IncomeStatement::CashPosition.new(family, accounts: user.finance_accounts)
    end
end
