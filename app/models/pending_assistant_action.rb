# frozen_string_literal: true

# A write the assistant proposed in a confirm-writes chat. Nothing is saved
# until the user confirms; #apply! then runs the same tool the model called,
# with the arguments it called it with, so the confirmed write takes exactly the
# path an unconfirmed one would have. Statement lines (kind statement_entry) are
# applied together through Assistant::StatementProposal instead.
class PendingAssistantAction < ApplicationRecord
  STATUSES = %w[pending applied cancelled failed].freeze
  KINDS = %w[create_entry update_entry delete_entry update_balance create_account create_label statement_entry other].freeze
  STATEMENT_FUNCTION = "statement_entry"
  SHOWN_PER_CHAT = 300
  APPLY_FAILED_MESSAGE = "This could not be saved. Please try again."

  belongs_to :chat
  belongs_to :family
  belongs_to :user
  belongs_to :message, optional: true

  validates :status, inclusion: { in: STATUSES }
  validates :kind, inclusion: { in: KINDS }
  validates :function_name, :summary, presence: true

  scope :ordered, -> { order(:created_at, :id) }
  scope :unresolved, -> { where(status: %w[pending failed]) }

  STATUSES.each do |value|
    define_method(:"#{value}?") { status == value }
  end

  class << self
    # Stores the proposal for a write tool and returns what the model sees in
    # place of the tool's result. An invalid call is handed back as the tool's
    # own error, so the model can correct it before the user is asked anything.
    def propose!(chat:, function:, arguments:, provider_call_id: nil)
      preview = function.preview(arguments)
      return preview if preview.is_a?(Hash) && preview[:success] == false

      action = create!(
        chat: chat,
        family: chat.user.family,
        user: chat.user,
        provider_call_id: provider_call_id,
        function_name: function.name,
        arguments: arguments,
        kind: preview[:kind],
        summary: preview[:summary],
        details: preview[:details] || {}
      )

      {
        success: true,
        status: "awaiting_confirmation",
        pending_action_id: action.id,
        summary: action.summary,
        message: "Nothing is saved yet. The user sees a card with Save and Cancel. Tell them in one short line what you prepared and to tap Save. Do not claim it is saved."
      }
    end

    # Applies the given open actions, statement lines grouped per import.
    # Already-applied or cancelled actions are left as they are, so a repeated
    # confirm (double tap, retried request) never writes twice.
    def confirm_all!(actions)
      statement_lines, tool_actions = actions.partition { |a| a.kind == "statement_entry" }
      tool_actions.each(&:apply!)
      statement_lines.group_by { |a| a.arguments["import_id"] }.each_value do |lines|
        Assistant::StatementProposal.apply!(lines)
      end
      actions.each(&:reload)
    end
  end

  def apply!
    with_lock do
      return self unless pending? || failed?

      outcome = run_tool
      if outcome.is_a?(Hash) && outcome[:success] == false
        update!(status: "failed", error: outcome[:message].presence || outcome[:error].to_s)
      else
        update!(status: "applied", result: outcome, error: nil, applied_at: Time.current)
        record_outcome_for_model(outcome)
      end
    end
    self
  end

  def cancel!
    with_lock do
      return self unless pending? || failed?

      update!(status: "cancelled")
      record_outcome_for_model({ status: "cancelled_by_user", message: "The user cancelled this. Nothing was saved." })
    end
    self
  end

  # The assistant message whose turn proposed this; set once the turn's tool
  # calls are saved (see Assistant::Builtin).
  def tool_call
    return if message_id.blank? || provider_call_id.blank?

    ToolCall.find_by(message_id: message_id, provider_call_id: provider_call_id)
  end

  private
    def run_tool
      # Re-resolved for the user now, so a tool the user lost access to since
      # the proposal (guest demotion, preview turned off) cannot be applied.
      function_class = Assistant.function_classes(user).find { |fc| fc.name == function_name }
      return { success: false, error: "unknown_tool", message: APPLY_FAILED_MESSAGE } unless function_class

      # A savepoint, so a tool that raises after writing leaves nothing behind
      # and a retried Save cannot write twice.
      self.class.transaction(requires_new: true) { function_class.new(user).call(arguments) }
    rescue => e
      Rails.logger.error("PendingAssistantAction #{id} (#{function_name}) failed: #{e.class}: #{e.message}")
      { success: false, error: "apply_failed", message: APPLY_FAILED_MESSAGE }
    end

    # Rewrites the proposing tool call's result, so the model's history for
    # later turns says what really happened (and carries the created ids an
    # edit or delete needs) instead of "awaiting confirmation".
    def record_outcome_for_model(outcome)
      call = tool_call
      return unless call

      call.update!(function_result: { status: applied? ? "saved_after_user_confirmed" : status, result: outcome })
    end
end
