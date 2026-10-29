# frozen_string_literal: true

# Save / Cancel on the assistant's confirm cards. Both are idempotent: an
# action that is already applied or cancelled is returned unchanged.
class Api::V1::PendingActionsController < Api::V1::BaseController
  MAX_IDS = 200

  before_action :require_ai_enabled
  before_action -> { authorize_scope!(:write) }
  before_action :set_chat
  before_action :set_actions

  def confirm
    @pending_actions = PendingAssistantAction.confirm_all!(@actions)
    render :index
  end

  def cancel
    @pending_actions = @actions.each(&:cancel!)
    render :index
  end

  private
    def set_chat
      @chat = current_resource_owner.chats.find(params[:chat_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "not_found", message: "Chat not found" }, status: :not_found
    end

    def set_actions
      ids = Array(params[:ids]).map(&:to_s).compact_blank.uniq
      if ids.empty? || ids.size > MAX_IDS
        return render json: { error: "validation_failed", message: "ids must list 1 to #{MAX_IDS} pending actions" }, status: :unprocessable_entity
      end

      @actions = @chat.pending_assistant_actions.where(id: ids.select { |id| UuidFormat.valid?(id) }).ordered.to_a
      render json: { error: "not_found", message: "Pending action not found" }, status: :not_found if @actions.size != ids.size
    end
end
