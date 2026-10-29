class Assistant::Function::UpdateTransaction < Assistant::Function
  class << self
    def name
      "update_transaction"
    end

    def description
      <<~INSTRUCTIONS
        Updates an existing transaction.

        Use get_transactions first to find the transaction id, and get_categories,
        get_tags, or the current transaction merchant before referencing related ids.

        This tool can update the transaction name, notes, category, merchant,
        tags, amount and date. It will not edit split child transactions directly.

        Amount follows create_transaction: a positive amount with `type`
        ("expense" or "income"), or a signed amount (negative = income).
      INSTRUCTIONS
    end
  end

  def strict_mode?
    false
  end

  def params_schema
    build_schema(
      required: [ "id" ],
      properties: {
        id: {
          type: "string",
          description: "Transaction ID from get_transactions"
        },
        name: {
          type: "string",
          description: "New transaction name. Omit to leave unchanged."
        },
        notes: {
          type: [ "string", "null" ],
          description: "New transaction notes. Use null to clear notes. Omit to leave unchanged."
        },
        category_id: {
          type: [ "string", "null" ],
          description: "Category ID from get_categories. Use null to clear category. Omit to leave unchanged."
        },
        merchant_id: {
          type: [ "string", "null" ],
          description: "Merchant ID currently available to the family. Use null to clear merchant. Omit to leave unchanged."
        },
        tag_ids: {
          type: "array",
          items: { type: "string" },
          description: "Full list of tag IDs to set. Use an empty array to clear all tags. Omit to leave unchanged."
        },
        amount: {
          type: "number",
          description: "New amount. Negative = income, positive = expense, unless `type` is given. Omit to leave unchanged."
        },
        type: {
          type: "string",
          enum: %w[income expense],
          description: "Optional with amount: income -> money in, expense -> money out; the magnitude of amount is used."
        },
        date: {
          type: "string",
          description: "New date, YYYY-MM-DD. Omit to leave unchanged."
        }
      }
    )
  end

  def call(params = {})
    prepared = prepare(params)
    return prepared if error_response?(prepared)

    transaction = prepared[:transaction]
    entry = transaction.entry
    entry_attrs = prepared[:entry_attrs]
    tag_ids = prepared[:tag_ids]

    Entry.transaction do
      entry.update!(entry_attrs)

      if params.key?("tag_ids")
        transaction.tag_ids = tag_ids
        transaction.save!
        transaction.lock_attr!(:tag_ids)
      end

      entry.sync_account_later
      entry.lock_saved_attributes!
    end

    {
      success: true,
      transaction: serialize(transaction.reload),
      message: "Transaction '#{transaction.entry.name}' updated."
    }
  rescue ActiveRecord::RecordInvalid => e
    error("validation_failed", e.record.errors.full_messages.join("; "))
  end

  def confirmation_preview(params = {})
    prepared = prepare(params)
    return prepared if error_response?(prepared)

    entry = prepared[:transaction].entry
    attrs = prepared[:entry_attrs]
    amount = attrs.fetch(:amount, entry.amount)
    date = attrs.fetch(:date, entry.date)
    entryable = attrs[:entryable_attributes] || {}
    category = entryable.key?(:category_id) ? family.categories.find_by(id: entryable[:category_id]) : prepared[:transaction].category
    amount_formatted = format_amount(amount.abs, entry.currency)

    {
      kind: "update_entry",
      summary: preview_summary("Change #{entry.name}", amount_formatted, category&.name, format_preview_date(date), entry.account.name),
      details: {
        direction: amount.negative? ? "in" : "out",
        amount: amount.abs.to_s,
        amount_formatted: amount_formatted,
        date: date.iso8601,
        description: attrs.fetch(:name, entry.name),
        label: category&.name,
        account: entry.account.name,
        note: attrs.fetch(:notes, entry.notes)
      }
    }
  end

  private
    # Validates the call without writing. Returns { transaction:,
    # entry_attrs:, tag_ids: } or an error hash.
    def prepare(params)
      transaction = find_transaction(params["id"])
      return error("not_found", "Transaction with id '#{params["id"]}' not found.") unless transaction

      entry = transaction.entry
      return error("split_child", "Split child transactions cannot be edited directly. Use the split editor.") if entry.split_child?
      return error("not_authorized", "You do not have permission to update this transaction.") unless permitted_to_update?(entry.account, params)

      entry_attrs = entry_attributes(params, entry)
      return entry_attrs if error_response?(entry_attrs)

      tag_ids = nil
      if params.key?("tag_ids")
        tag_ids = Array(params["tag_ids"]).map(&:to_s).reject(&:blank?)
        return error("invalid_tags", "One or more tag_ids do not belong to the user's family.") unless valid_tag_ids?(tag_ids)
      end

      return error("no_changes", "Provide at least one field to update.") if no_changes?(entry_attrs, params)

      { transaction: transaction, entry_attrs: entry_attrs, tag_ids: tag_ids }
    end

    def find_transaction(id)
      return nil unless valid_uuid?(id)

      family.transactions
        .joins(:entry)
        .where(entries: { account_id: user.accessible_accounts.visible.select(:id) })
        .find_by(id: id)
    end

    def permitted_to_update?(account, params)
      permission = account.permission_for(user)
      return true if permission.in?([ :owner, :full_control ])

      permission == :read_write && (params.keys & %w[name amount date]).empty?
    end

    def entry_attributes(params, entry)
      entryable_attrs = { id: entry.entryable_id }

      if params.key?("category_id")
        category_id = optional_uuid(params["category_id"])
        return category_id if error_response?(category_id)
        return error("invalid_category", "category_id does not belong to the user's family.") if category_id && !family.categories.exists?(id: category_id)

        entryable_attrs[:category_id] = category_id
      end

      if params.key?("merchant_id")
        merchant_id = optional_uuid(params["merchant_id"])
        return merchant_id if error_response?(merchant_id)
        return error("invalid_merchant", "merchant_id is not available to the user's family.") if merchant_id && !available_merchants.exists?(id: merchant_id)

        entryable_attrs[:merchant_id] = merchant_id
      end

      attrs = {}

      if params.key?("amount")
        amount = parse_amount(params["amount"])
        return error("invalid_amount", "amount must be a number.") if amount.nil?

        attrs[:amount] = case params["type"].to_s.downcase
        when "income" then -amount.abs
        when "expense" then amount.abs
        else amount
        end
      end

      if params.key?("date")
        date = parse_date(params["date"])
        return error("invalid_date", "date must be an ISO 8601 date (YYYY-MM-DD).") unless date

        attrs[:date] = date
      end

      attrs[:name] = params["name"].to_s.strip if params.key?("name")
      attrs[:notes] = params["notes"] if params.key?("notes")
      attrs[:entryable_attributes] = entryable_attrs if entryable_attrs.keys.size > 1
      attrs
    end

    def optional_uuid(value)
      return nil if value.nil? || value == ""
      return value.to_s if valid_uuid?(value)

      error("invalid_uuid", "Expected a valid UUID.")
    end

    def parse_amount(value)
      number = BigDecimal(value.to_s)
      number.finite? ? number : nil
    rescue ArgumentError, TypeError
      nil
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end

    def valid_tag_ids?(tag_ids)
      family.tags.where(id: tag_ids).count == tag_ids.uniq.size
    end

    def available_merchants
      family.available_merchants_for(user)
    end

    def no_changes?(entry_attrs, params)
      entry_attrs.empty? && !params.key?("tag_ids")
    end

    def serialize(transaction)
      entry = transaction.entry
      {
        id: transaction.id,
        name: entry.name,
        date: entry.date,
        amount: entry.amount.to_s,
        currency: entry.currency,
        notes: entry.notes,
        category: transaction.category && {
          id: transaction.category.id,
          name: transaction.category.name
        },
        merchant: transaction.merchant && {
          id: transaction.merchant.id,
          name: transaction.merchant.name
        },
        tags: transaction.tags.map { |tag| { id: tag.id, name: tag.name } }
      }
    end

    def error_response?(value)
      value.is_a?(Hash) && value[:success] == false
    end

    def error(key, message)
      { success: false, error: key, message: message }
    end
end
