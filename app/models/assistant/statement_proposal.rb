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
    import = first.family.imports.find_by(id: first.arguments["import_id"])
    return fail_lines(lines) unless import

    new(chat: first.chat, import: import).apply!(lines)
  end

  def self.fail_lines(lines)
    lines.each do |line|
      line.update!(status: "failed", error: I18n.t("assistant.statements.not_publishable")) if line.reload.pending? || line.failed?
    end
  end

  def initialize(chat:, import:)
    @chat = chat
    @import = import
  end

  # Posts the assistant's summary and the batch. Returns :wait while the
  # import is still being read, otherwise the new AssistantMessage (nil when
  # this chat already has the import's batch).
  def propose!(file_name: nil)
    import.with_lock do
      return :wait if still_reading?
      return if batch.exists?
      return post(I18n.t("assistant.statements.failed", error: import.error.presence || "-")) if import.failed?

      rows = import.pending? ? import.rows.ordered.limit(MAX_LINES).to_a.select(&:valid?) : []
      return post(I18n.t("assistant.statements.no_lines", file: file_label(file_name))) if rows.empty?

      lines = lines_for(rows)
      message = post(summary(file_name, lines))
      lines.each { |line| create_line!(line, message) }
      message
    end
  end

  # Keeps only the confirmed lines on the import, sets their suggested labels
  # and publishes it. Every other open line of the batch is cancelled: an
  # import publishes once. Repeating the call after publishing is a no-op.
  #
  # The import job is enqueued only after the row changes commit, so it can
  # never read rows the user removed, and the rows are checked once more
  # against the confirmed set right before it is enqueued.
  def apply!(lines)
    keep = nil

    import.with_lock do
      confirmed = lines.select { |line| line.reload.pending? || line.failed? }
      next if confirmed.empty?
      next self.class.fail_lines(confirmed) unless import.pending? && import.accounts_writable_by?(chat.user)

      keep = confirmed.to_h { |line| [ line.arguments["row_id"], line.arguments["category_id"] ] }
      categories = import.family.categories.where(id: keep.values.compact).index_by(&:id)

      import.rows.where.not(id: keep.keys).delete_all
      import.rows.where(id: keep.keys).find_each do |row|
        row.update_column(:category, categories[keep[row.id]]&.name.to_s)
      end
      import.update_column(:rows_count, import.rows.count)
      import.sync_mappings

      now = Time.current
      batch.where(id: confirmed.map(&:id)).update_all(status: "applied", error: nil, applied_at: now, result: { import_id: import.id }, updated_at: now)
      batch.unresolved.where.not(id: confirmed.map(&:id)).update_all(status: "cancelled", updated_at: now)
    end

    publish!(lines, keep.keys) if keep
  rescue StandardError => e
    Rails.logger.error("Statement batch for import #{import.id} could not be saved: #{e.class}: #{e.message}")
    self.class.fail_lines(lines)
  end

  private
    def batch
      chat.pending_assistant_actions.where(kind: "statement_entry").where("arguments ->> 'import_id' = ?", import.id)
    end

    def publish!(lines, row_ids)
      unchanged = import.with_lock { import.pending? && import.rows.pluck(:id).sort == row_ids.sort }
      raise "Import rows changed before publishing" unless unchanged

      import.publish_later
    rescue StandardError => e
      Rails.logger.error("Statement import #{import.id} was not published: #{e.class}: #{e.message}")
      # The rows are already narrowed to the confirmed lines, so failing them
      # lets the user press Save again to retry the publish.
      batch.where(id: lines.map(&:id), status: "applied").update_all(status: "failed", error: I18n.t("assistant.statements.not_publishable"), updated_at: Time.current)
    end

    # A PDF is pending before its AI pass as well as after it.
    def still_reading?
      import.importing? || (import.is_a?(PdfImport) && import.pending? && !import.ai_processed?)
    end

    def post(content)
      chat.messages.create!(type: "AssistantMessage", content: content, ai_model: Chat.default_model(chat.user.family), status: "complete")
    end

    def create_line!(line, message)
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

    def lines_for(rows)
      parsed = rows.filter_map do |row|
        amount = row.signed_amount
        currency = row.currency.presence || import.account&.currency || import.family.currency
        [ row, amount, currency, Date.iso8601(row.date_iso) ]
      rescue ArgumentError, TypeError
        nil
      end

      recorded = recorded_keys(parsed.map { |_, _, _, date| date })

      parsed.map do |row, amount, currency, date|
        category = suggested_category(row)
        formatted = Money.new(amount.abs, currency).format

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
            duplicate: recorded.include?([ date, amount.to_d, currency ])
          }
        }
      end
    end

    # One query for the whole batch: [date, amount, currency] of the
    # account's transactions over the statement's dates, the same match the
    # import job's duplicate check makes (same day, amount and currency).
    def recorded_keys(dates)
      return Set.new if dates.empty? || import.account.nil?

      import.account.entries.where(entryable_type: "Transaction", date: dates.min..dates.max)
        .pluck(:date, :amount, :currency).to_set { |date, amount, currency| [ date, amount.to_d, currency ] }
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
