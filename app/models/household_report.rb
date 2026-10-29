# Household report for a date range: the money in and out of a family's
# accounts, optionally narrowed to some labels (categories) and accounts.
# Rendered as a PDF by HouseholdReport::Pdf.
#
# Transfers between the household's own accounts and rows the user excluded
# (which includes split parents) are left out, as in the month view. Amounts
# stay in each account's currency; totals are kept per currency.
class HouseholdReport
  include ActiveModel::Validations

  MAX_MONTHS = 24
  MAX_ENTRIES = 5_000
  # Money moving between the household's own accounts is neither in nor out.
  SKIPPED_KINDS = Transaction::UNCATEGORIZED_EXCLUDED_KINDS
  # Outflows whatever their sign (see IncomeStatement::ScopedTransactionsQuery).
  OUTFLOW_KINDS = %w[loan_payment investment_contribution].freeze

  Row = Data.define(:date, :name, :category, :account_name, :currency, :amount, :direction)

  Total = Data.define(:currency, :money_in, :money_out, :count) do
    def net = money_in - money_out
  end

  LabelTotal = Data.define(:category, :currency, :money_in, :money_out, :count)

  attr_reader :family, :user, :start_date, :end_date, :categories, :accounts, :include_uncategorized

  validate :period_is_valid
  validate :rows_within_limit, if: -> { errors.empty? }

  # categories: nil means every label (and unlabelled rows unless
  # include_uncategorized is false). A list means only those labels and their
  # sublabels, plus unlabelled rows when include_uncategorized is true.
  # accounts: nil means every account the user can see.
  def initialize(family:, user:, start_date:, end_date:, categories: nil, accounts: nil, include_uncategorized: nil)
    @family = family
    @user = user
    @start_date = start_date
    @end_date = end_date
    @categories = categories
    @accounts = accounts
    @include_uncategorized = include_uncategorized.nil? ? categories.nil? : include_uncategorized
  end

  def all_labels?
    categories.nil? && include_uncategorized
  end

  def all_accounts?
    accounts.nil?
  end

  def rows
    @rows ||= scope.map { |transaction| row_for(transaction) }
  end

  def rows_by_month
    rows.group_by { |row| row.date.beginning_of_month }
  end

  def totals(for_rows = rows)
    for_rows.group_by(&:currency).sort_by { |currency, _| currency_order(currency) }.map do |currency, group|
      Total.new(currency:, money_in: sum(group, :in), money_out: sum(group, :out), count: group.size)
    end
  end

  def label_totals
    rows.group_by { |row| [ row.category, row.currency ] }.map do |(category, currency), group|
      LabelTotal.new(category:, currency:, money_in: sum(group, :in), money_out: sum(group, :out), count: group.size)
    end.sort_by { |t| [ currency_order(t.currency), -t.money_out, -t.money_in, t.category&.name.to_s ] }
  end

  def currencies
    rows.map(&:currency).uniq
  end

  def to_pdf
    HouseholdReport::Pdf.new(self).render
  end

  private
    def scope
      query = family.transactions.visible.excluding_pending
        .where(entries: { date: start_date..end_date, excluded: false, account_id: account_scope.select(:id) })
        .where.not(kind: SKIPPED_KINDS)
        .includes(:category, entry: :account)
        .merge(Entry.chronological)
      label_filter(query)
    end

    def account_scope
      scope = family.accounts.accessible_by(user).where.not(status: "pending_deletion")
      accounts.nil? ? scope : scope.where(id: accounts.map(&:id))
    end

    def label_filter(query)
      return query if categories.nil? && include_uncategorized

      ids = categories.nil? ? family.categories.select(:id) : category_ids_with_sublabels
      matching = Transaction.where(category_id: ids)
      matching = matching.or(Transaction.where(category_id: nil)) if include_uncategorized
      query.merge(matching)
    end

    def category_ids_with_sublabels
      ids = categories.map(&:id)
      ids + family.categories.where(parent_id: ids).pluck(:id)
    end

    def row_for(transaction)
      entry = transaction.entry
      direction = entry.amount.negative? && OUTFLOW_KINDS.exclude?(transaction.kind) ? :in : :out
      Row.new(
        date: entry.date,
        name: entry.name,
        category: transaction.category,
        account_name: entry.account.name,
        currency: entry.currency,
        amount: entry.amount.abs,
        direction:
      )
    end

    def sum(rows, direction)
      rows.select { |row| row.direction == direction }.sum(BigDecimal("0"), &:amount)
    end

    # Family currency first, the rest alphabetically.
    def currency_order(currency)
      [ currency == family.currency ? 0 : 1, currency ]
    end

    def period_is_valid
      if start_date.blank? || end_date.blank?
        errors.add(:base, "start_date and end_date are required (YYYY-MM-DD)")
      elsif start_date > end_date
        errors.add(:base, "start_date must be on or before end_date")
      elsif end_date >= start_date.advance(months: MAX_MONTHS)
        errors.add(:base, "The report can cover at most #{MAX_MONTHS} months")
      end
    end

    def rows_within_limit
      return if scope.limit(MAX_ENTRIES + 1).count <= MAX_ENTRIES

      errors.add(:base, "The report has more than #{MAX_ENTRIES} entries; choose a shorter period")
    end
end
