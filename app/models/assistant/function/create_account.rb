# frozen_string_literal: true

# Creates a manual account through the same path as the app's account form and
# POST /api/v1/accounts: create_and_sync writes the opening balance valuation
# and the creating user owns the account.
class Assistant::Function::CreateAccount < Assistant::Function
  # Household words for account kinds, mapped to Sure's accountable types.
  ACCOUNT_KINDS = {
    "cash" => [ "Depository", "cash" ],
    "bank" => [ "Depository", "checking" ],
    "savings" => [ "Depository", "savings" ],
    "credit_card" => [ "CreditCard", "credit_card" ],
    "loan" => [ "Loan", "other" ],
    "other_asset" => [ "OtherAsset", nil ],
    "other_liability" => [ "OtherLiability", nil ]
  }.freeze

  class << self
    def name
      "create_account"
    end

    def description
      <<~INSTRUCTIONS
        Creates a new manual account (where money is kept or owed), such as
        "Cash in hand", a bank account, a committee/savings pot, a credit card
        or a loan.

        `balance` is what the account holds today (for a credit card or loan,
        the positive amount owed). It is recorded as the opening balance.
        Check get_accounts first so you do not create a duplicate.
      INSTRUCTIONS
    end
  end

  def strict_mode?
    false
  end

  def params_schema
    build_schema(
      required: %w[name kind],
      properties: {
        name: { type: "string", description: "Account name, e.g. \"Cash in hand\"." },
        kind: { type: "string", enum: ACCOUNT_KINDS.keys, description: "What kind of account this is." },
        balance: { type: "number", description: "Balance today. Defaults to 0. For credit_card/loan, the amount owed as a positive number." },
        currency: { type: "string", description: "ISO 4217 code. Defaults to the family currency." }
      }
    )
  end

  def confirmation_preview(params = {})
    attrs = prepare(params)
    return attrs if attrs[:success] == false

    balance_formatted = format_amount(attrs[:balance], attrs[:currency])
    {
      kind: "create_account",
      summary: preview_summary("New account", attrs[:name], balance_formatted),
      details: { name: attrs[:name], amount: attrs[:balance].to_s, amount_formatted: balance_formatted }
    }
  end

  def call(params = {})
    attrs = prepare(params)
    return attrs if attrs[:success] == false

    account = Account.transaction do
      family.accounts.create_and_sync(attrs.merge(owner: user), opening_balance_date: Time.zone.today - 2.years).tap(&:lock_saved_attributes!)
    end

    {
      success: true,
      account: { id: account.id, name: account.name, type: account.accountable_type, balance: account.balance.to_s, currency: account.currency },
      message: "Created account #{account.name}."
    }
  rescue ActiveRecord::RecordInvalid => e
    error("validation_failed", e.record.errors.full_messages.join("; "))
  end

  private
    def prepare(params)
      return error("forbidden", "Guests cannot create accounts.") if user.guest?

      name = params["name"].to_s.strip
      return error("invalid_name", "name is required.") if name.empty?
      return error("already_exists", "An account named '#{name}' already exists.") if family.accounts.visible.where("LOWER(name) = ?", name.downcase).exists?

      accountable_type, subtype = ACCOUNT_KINDS[params["kind"].to_s]
      return error("invalid_kind", "kind must be one of: #{ACCOUNT_KINDS.keys.join(", ")}.") unless accountable_type

      balance = params["balance"].blank? ? 0.to_d : BigDecimal(params["balance"].to_s)
      return error("invalid_balance", "balance must be a number.") unless balance.finite?
      return error("negative_balance", "balance cannot be negative. For a credit card or loan, pass the amount owed as a positive number; otherwise ask the user what the account holds.") if balance.negative?

      currency = params["currency"].to_s.strip.upcase.presence || family.currency
      Money::Currency.new(currency)

      { name: name, accountable_type: accountable_type, subtype: subtype, balance: balance, currency: currency }.compact
    rescue ArgumentError, TypeError
      error("invalid_balance", "balance must be a number.")
    rescue Money::Currency::UnknownCurrencyError
      error("invalid_currency", "currency must be a valid ISO 4217 code.")
    end

    def error(key, message)
      { success: false, error: key, message: message }
    end
end
