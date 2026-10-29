# frozen_string_literal: true

# Turns a statement import attached in the chat into a batch of confirm-card
# lines, and publishes the import with the lines the user kept.
#
# Parsing, duplicate handling and labelling stay in the import pipeline: the
# rows are the import's own rows (PDF via AI, CSV without), publishing runs the
# import job (which skips or merges lines already on the account) and keyword
# rules run afterwards as for any import. This class only adds the suggestion
# shown on each line and the user's per-line choice.
class Assistant::StatementProposal
  FUNCTION_NAME = PendingAssistantAction::STATEMENT_FUNCTION
  MAX_LINES = 200

  attr_reader :chat, :import

  def self.apply!(lines)
    first = lines.first
    new(chat: first.chat, import: first.family.imports.find(first.arguments["import_id"])).apply!(lines)
  end

  def initialize(chat:, import:)
    @chat = chat
    @import = import
  end

  # Posts the assistant's summary and the batch. Returns :wait while the
  # import is still being read, otherwise the new AssistantMessage.
  def propose!(file_name: nil)
    import.reload
    return :wait if still_reading?
    return post(I18n.t("assistant.statements.failed", error: import.error.presence || "-")) if import.failed?

    rows = import.pending? ? import.rows_ordered.to_a.select(&:valid?).first(MAX_LINES) : []
    return post(I18n.t("assistant.statements.no_lines", file: file_label(file_name))) if rows.empty?

    lines = rows.map { |row| line_for(row) }
    message = post(summary(file_name, lines))

    lines.each do |line|
      chat.pending_assistant_actions.create!(
        family: chat.user.family,
        user: chat.user,
        message: message,
        function_name: FUNCTION_NAME,
        kind: "statement_entry",
        arguments: { import_id: import.id, row_id: line[:row].id, category_id: line[:category]&.id },
        summary: line[:summary],
        details: line[:details]
      )
    end

    message
  end

  # Keeps only the confirmed lines on the import, sets their suggested labels
  # and publishes it. Every other open line of the batch is cancelled: an
  # import publishes once. Repeating the call after publishing is a no-op.
  def apply!(lines)
    import.with_lock do
      confirmed = lines.select { |line| line.reload.pending? || line.failed? }
      next if confirmed.empty?

      unless import.pending? && import.accounts_writable_by?(chat.user)
        fail_lines(confirmed)
        next
      end

      keep = confirmed.to_h { |line| [ line.arguments["row_id"], line.arguments["category_id"] ] }
      categories = import.family.categories.where(id: keep.values.compact).index_by(&:id)

      import.rows.where.not(id: keep.keys).delete_all
      import.rows.where(id: keep.keys).find_each do |row|
        row.update_column(:category, categories[keep[row.id]]&.name.to_s)
      end
      import.update_column(:rows_count, keep.size)
      import.sync_mappings
      import.publish_later

      now = Time.current
      batch = chat.pending_assistant_actions.where(kind: "statement_entry").where("arguments ->> 'import_id' = ?", import.id)
      batch.where(id: confirmed.map(&:id)).update_all(status: "applied", error: nil, applied_at: now, result: { import_id: import.id }, updated_at: now)
      batch.unresolved.where.not(id: confirmed.map(&:id)).update_all(status: "cancelled", updated_at: now)
    end
  rescue Import::MaxRowCountExceededError, RuntimeError => e
    Rails.logger.error("Statement batch for import #{import.id} could not publish: #{e.class}: #{e.message}")
    fail_lines(lines.select { |line| line.reload.pending? })
  end

  private
    # A PDF is pending before its AI pass as well as after it.
    def still_reading?
      import.importing? || (import.is_a?(PdfImport) && import.pending? && !import.ai_processed?)
    end

    def fail_lines(lines)
      lines.each { |line| line.update!(status: "failed", error: I18n.t("assistant.statements.not_publishable")) }
    end

    def post(content)
      chat.messages.create!(type: "AssistantMessage", content: content, ai_model: Chat.default_model, status: "complete")
    end

    def line_for(row)
      amount = row.signed_amount
      currency = row.currency.presence || import.account&.currency || import.family.currency
      category = suggested_category(row)
      formatted = Money.new(amount.abs, currency).format
      date = Date.iso8601(row.date_iso)

      {
        row: row,
        category: category,
        summary: [ formatted, row.name, category&.name, I18n.l(date, format: :long) ].compact_blank.join(" · "),
        details: {
          direction: amount.negative? ? "in" : "out",
          amount: amount.abs.to_s,
          amount_formatted: formatted,
          date: date.iso8601,
          description: row.name,
          label: category&.name,
          account: import.account&.name,
          note: row.notes.presence,
          duplicate: duplicate?(row, amount, currency)
        }
      }
    end

    # The label the statement itself names when it is one of the family's
    # labels, else the first keyword rule whose word is in the line's name.
    # Unknown label names are dropped rather than created.
    def suggested_category(row)
      categories_by_name[row.category.to_s.strip.downcase] ||
        keyword_rules.find { |keyword, _| row.name.to_s.downcase.include?(keyword) }&.last
    end

    def categories_by_name
      @categories_by_name ||= import.family.categories.index_by { |c| c.name.downcase }
    end

    # [keyword, category] for each active auto-label keyword rule
    # (Rule.create_keyword_category_rule!).
    def keyword_rules
      @keyword_rules ||= begin
        categories = import.family.categories.index_by { |c| c.id.to_s }
        import.family.rules.where(active: true, resource_type: "transaction").includes(:conditions, :actions).filter_map do |rule|
          condition = rule.conditions.find { |c| c.condition_type == "transaction_name" && c.operator == "like" }
          action = rule.actions.find { |a| a.action_type == "set_transaction_category" }
          category = categories[action&.value.to_s]
          [ condition.value.to_s.downcase, category ] if condition&.value.present? && category
        end
      end
    end

    # The same lookup the PDF import uses when it reconciles lines.
    def duplicate?(row, amount, currency)
      return false unless import.account

      Account::ProviderImportAdapter.new(import.account)
        .find_duplicate_transaction(date: row.date_iso, amount: amount, currency: currency, include_provider_entries: true)
        .present?
    rescue ArgumentError, TypeError
      false
    end

    def summary(file_name, lines)
      I18n.t(
        "assistant.statements.proposed",
        count: lines.size,
        file: file_label(file_name),
        duplicates: lines.count { |l| l[:details][:duplicate] },
        unlabelled: lines.count { |l| l[:category].nil? }
      )
    end

    def file_label(file_name)
      file_name.presence || I18n.t("assistant.statements.default_file")
    end
end
