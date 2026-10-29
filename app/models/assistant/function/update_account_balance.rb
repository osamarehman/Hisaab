# frozen_string_literal: true

# Sets what an account holds today through set_current_balance, the same
# valuation path as the web's balance edit and PATCH /api/v1/accounts/:id.
class Assistant::Function::UpdateAccountBalance < Assistant::Function
  class << self
    def name
      "update_account_balance"
    end

    def description
      <<~INSTRUCTIONS
        Sets an account's balance as of today, e.g. after the user counts the
        cash in hand ("cash mein ab 12000 hain"). Recorded as a balance update,
        not as an expense or income. For a credit card or loan, pass the
        positive amount owed. Use get_accounts for the account id.
      INSTRUCTIONS
    end
  end

  def strict_mode?
    false
  end

  def params_schema
    build_schema(
      required: %w[account_id balance],
      properties: {
        account_id: { type: "string", description: "Account id from get_accounts." },
        balance: { type: "number", description: "The balance today, in the account's currency." }
      }
    )
  end

  def confirmation_preview(params = {})
    prepared = prepare(params)
    return prepared if prepared[:success] == false

    account = prepared[:account]
    formatted = format_amount(prepared[:balance], account.currency)
    {
      kind: "update_balance",
      summary: preview_summary("Set #{account.name} to #{formatted}", "was #{account.balance_money.format}"),
      details: { account: account.name, amount: prepared[:balance].to_s, amount_formatted: formatted, date: Date.current.iso8601 }
    }
  end

  def call(params = {})
    prepared = prepare(params)
    return prepared if prepared[:success] == false

    account = prepared[:account]
    result = account.set_current_balance(prepared[:balance])
    return error("update_failed", result.error.to_s) unless result.success?

    account.reload
    {
      success: true,
      account: { id: account.id, name: account.name, balance: account.balance.to_s, currency: account.currency },
      message: "#{account.name} now shows #{account.balance_money.format}."
    }
  end

  private
    def prepare(params)
      account = family.accounts.writable_by(user).find_by(id: params["account_id"]) if valid_uuid?(params["account_id"])
      return error("account_not_found", "No account with that id that you can change.") unless account

      balance = BigDecimal(params["balance"].to_s)
      return error("invalid_balance", "balance must be a number.") unless balance.finite?

      { account: account, balance: balance }
    rescue ArgumentError, TypeError
      error("invalid_balance", "balance must be a number.")
    end

    def error(key, message)
      { success: false, error: key, message: message }
    end
end
