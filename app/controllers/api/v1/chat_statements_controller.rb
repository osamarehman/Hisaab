# frozen_string_literal: true

# Hands a statement the app already uploaded (POST /api/v1/imports) to the
# chat: records it as the user's message, then AssistantStatementJob posts the
# lines to confirm once the import has been read.
class Api::V1::ChatStatementsController < Api::V1::BaseController
  STATEMENT_TYPES = %w[PdfImport TransactionImport].freeze

  before_action :require_ai_enabled
  before_action -> { authorize_scope!(:write) }
  before_action :set_chat

  def create
    import = find_import
    return render_error("not_found", "Statement import not found", :not_found) unless import
    return render_error("validation_failed", "The import needs an account you can write to") unless import.account && import.accounts_writable_by?(current_resource_owner)
    return render_error("validation_failed", "This statement was already imported") unless import.pending? || import.importing?

    file_name = params[:file_name].to_s.strip.first(120).presence
    @message = @chat.messages.create!(
      type: "UserMessage",
      content: I18n.t("assistant.statements.attached", file: file_name || I18n.t("assistant.statements.default_file")),
      ai_model: Chat.default_model,
      skip_assistant_response: true
    )
    AssistantStatementJob.perform_later(@chat, import, file_name)

    render :create, status: :accepted
  end

  private
    def set_chat
      @chat = current_resource_owner.chats.find(params[:chat_id])
    rescue ActiveRecord::RecordNotFound
      render_error("not_found", "Chat not found", :not_found)
    end

    def find_import
      id = params[:import_id].to_s
      return unless UuidFormat.valid?(id)

      current_resource_owner.family.imports.where(type: STATEMENT_TYPES).find_by(id: id)
    end

    def render_error(code, message, status = :unprocessable_entity)
      render json: { error: code, message: message }, status: status
    end
end
