require "test_helper"

# Statement attachments and voice notes posted into an assistant chat.
class Api::V1::ChatInputsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    @user.update!(ai_enabled: true)
    @chat = chats(:one)
    @user.api_keys.active.destroy_all
    @api_key = ApiKey.create!(user: @user, name: "Test", scopes: %w[read_write], source: "web", display_key: "test_rw_#{SecureRandom.hex(8)}")
    @import = imports(:pdf_with_rows)
    @import.update_column(:account_id, accounts(:depository).id)
  end

  test "attaching a statement records the user's message without asking the model" do
    assert_enqueued_with(job: AssistantStatementJob) do
      assert_no_enqueued_jobs(only: AssistantResponseJob) do
        post "/api/v1/chats/#{@chat.id}/statements", params: { import_id: @import.id, file_name: "march.pdf" }, headers: api_headers, as: :json
      end
    end

    assert_response :accepted
    message = JSON.parse(response.body)["message"]
    assert_equal "user_message", message["type"]
    assert_includes message["content"], "march.pdf"
  end

  test "attaching the same statement twice is refused" do
    2.times { post "/api/v1/chats/#{@chat.id}/statements", params: { import_id: @import.id }, headers: api_headers, as: :json }

    assert_response :unprocessable_entity
    assert_equal "already_attached", JSON.parse(response.body)["error"]
  end

  test "anything sent through the API turns on confirm for the chat" do
    @chat.update!(confirm_writes: false)
    Assistant::VoiceNote.any_instance.stubs(:transcribe!).returns("hello")

    post "/api/v1/chats/#{@chat.id}/voice_notes", params: { audio: audio_upload }, headers: api_headers
    assert @chat.reload.confirm_writes?

    @chat.update!(confirm_writes: false)
    post "/api/v1/chats/#{@chat.id}/messages", params: { content: "aaj 500 ki sabzi" }, headers: api_headers
    assert_response :created
    assert @chat.reload.confirm_writes?
  end

  test "voice notes are rate limited per user" do
    Api::V1::VoiceNotesController.cache_store.stubs(:increment).returns(21)

    post "/api/v1/chats/#{@chat.id}/voice_notes", params: { audio: audio_upload }, headers: api_headers

    assert_response :too_many_requests
    assert_equal "rate_limited", JSON.parse(response.body)["error"]
  end

  test "a statement must be an open import in the family" do
    post "/api/v1/chats/#{@chat.id}/statements", params: { import_id: SecureRandom.uuid }, headers: api_headers, as: :json
    assert_response :not_found

    post "/api/v1/chats/#{@chat.id}/statements", params: { import_id: imports(:pdf_processed).id }, headers: api_headers, as: :json
    assert_response :unprocessable_entity
  end

  test "a voice note becomes the user's message and asks the model" do
    Assistant::VoiceNote.any_instance.expects(:transcribe!).returns("kal 800 ka petrol dala")

    assert_enqueued_with(job: AssistantResponseJob) do
      post "/api/v1/chats/#{@chat.id}/voice_notes", params: { audio: audio_upload, duration_ms: 3000 }, headers: api_headers
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "kal 800 ka petrol dala", body["transcript"]
    assert_equal "kal 800 ka petrol dala", body["message"]["content"]
  end

  test "voice note errors come back as their code and a readable message" do
    Assistant::VoiceNote.any_instance.expects(:transcribe!).raises(Assistant::VoiceNote::Error.new("audio_too_long", "Voice notes can be up to 120 seconds."))

    assert_no_difference "Message.count" do
      post "/api/v1/chats/#{@chat.id}/voice_notes", params: { audio: audio_upload }, headers: api_headers
    end

    assert_response :unprocessable_entity
    assert_equal "audio_too_long", JSON.parse(response.body)["error"]
  end

  test "voice notes and statements respect the AI gate" do
    with_env_overrides AI_ALLOWED_EMAILS: "someone-else@example.com" do
      post "/api/v1/chats/#{@chat.id}/voice_notes", params: { audio: audio_upload }, headers: api_headers
      assert_response :forbidden

      post "/api/v1/chats/#{@chat.id}/statements", params: { import_id: @import.id }, headers: api_headers, as: :json
      assert_response :forbidden
    end
  end

  private
    def api_headers
      { "X-Api-Key" => @api_key.plain_key }
    end

    def audio_upload
      Rack::Test::UploadedFile.new(StringIO.new("RIFF0000WAVE"), "audio/wav", true, original_filename: "voice.wav")
    end
end
