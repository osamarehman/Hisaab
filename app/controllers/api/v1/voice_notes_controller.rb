# frozen_string_literal: true

# A voice note from the assistant composer: transcribed on the server
# (Assistant::VoiceNote), then posted as the user's message, which the
# assistant answers as if it had been typed.
class Api::V1::VoiceNotesController < Api::V1::BaseController
  before_action :require_ai_enabled
  before_action -> { authorize_scope!(:write) }
  before_action :set_chat
  before_action -> { @chat.require_confirmed_writes! }

  # Each note is a paid model call; generous for a household, a ceiling for a
  # leaked key.
  rate_limit to: 20, within: 1.hour, by: -> { current_resource_owner.id }, only: :create, name: "assistant-voice-note",
    with: -> { render json: { error: "rate_limited", message: I18n.t("assistant.voice.rate_limited") }, status: :too_many_requests }

  def create
    audio = params[:audio]
    unless audio.respond_to?(:read) && audio.respond_to?(:content_type)
      return render json: { error: "invalid_audio", message: I18n.t("assistant.voice.invalid_audio") }, status: :unprocessable_entity
    end

    @transcript = Assistant::VoiceNote.new(
      family: current_resource_owner.family,
      file: audio,
      duration_ms: params[:duration_ms].presence&.to_i
    ).transcribe!

    @message = @chat.messages.create!(type: "UserMessage", content: @transcript, ai_model: Chat.default_model(current_resource_owner.family))
    render :create, status: :created
  rescue Assistant::VoiceNote::Error => e
    render json: { error: e.code, message: e.message }, status: :unprocessable_entity
  end

  private
    def set_chat
      @chat = current_resource_owner.chats.find(params[:chat_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "not_found", message: "Chat not found" }, status: :not_found
    end
end
