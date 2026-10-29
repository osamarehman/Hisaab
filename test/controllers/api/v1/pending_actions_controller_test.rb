require "test_helper"

class Api::V1::PendingActionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    @user.update!(ai_enabled: true)
    @chat = chats(:one)
    @chat.update!(confirm_writes: true)
    @user.api_keys.active.destroy_all
    @api_key = ApiKey.create!(user: @user, name: "Test", scopes: %w[read_write], source: "web", display_key: "test_rw_#{SecureRandom.hex(8)}")
    @action = propose(name: "Sabzi")
  end

  test "requires authentication and AI access" do
    post "/api/v1/chats/#{@chat.id}/pending_actions/confirm", params: { ids: [ @action.id ] }
    assert_response :unauthorized

    @user.update!(ai_enabled: false)
    post "/api/v1/chats/#{@chat.id}/pending_actions/confirm", params: { ids: [ @action.id ] }, headers: api_headers
    assert_response :forbidden
  end

  test "confirm applies once and returns the updated actions" do
    assert_difference "Entry.count", 1 do
      2.times do
        post "/api/v1/chats/#{@chat.id}/pending_actions/confirm", params: { ids: [ @action.id ] }, headers: api_headers, as: :json
        assert_response :ok
      end
    end

    body = JSON.parse(response.body)
    assert_equal [ @action.id ], body["pending_actions"].map { |a| a["id"] }
    assert_equal "applied", body["pending_actions"].first["status"]
  end

  test "cancel leaves nothing saved" do
    assert_no_difference "Entry.count" do
      post "/api/v1/chats/#{@chat.id}/pending_actions/cancel", params: { ids: [ @action.id ] }, headers: api_headers, as: :json
    end

    assert_response :ok
    assert_equal "cancelled", JSON.parse(response.body)["pending_actions"].first["status"]
  end

  test "another user's chat and unknown ids are not found" do
    other_chat = chats(:two)
    post "/api/v1/chats/#{other_chat.id}/pending_actions/confirm", params: { ids: [ @action.id ] }, headers: api_headers, as: :json
    assert_response :not_found

    post "/api/v1/chats/#{@chat.id}/pending_actions/confirm", params: { ids: [ SecureRandom.uuid ] }, headers: api_headers, as: :json
    assert_response :not_found

    post "/api/v1/chats/#{@chat.id}/pending_actions/confirm", params: { ids: [] }, headers: api_headers, as: :json
    assert_response :unprocessable_entity
  end

  test "chat show lists pending actions and app chats confirm writes" do
    get "/api/v1/chats/#{@chat.id}", headers: api_headers
    assert_response :ok
    action = JSON.parse(response.body)["pending_actions"].first
    assert_equal "create_entry", action["kind"]
    assert_equal "pending", action["status"]
    assert action["summary"].present?

    post "/api/v1/chats", params: { title: "New" }, headers: api_headers
    assert Chat.find(JSON.parse(response.body)["id"]).confirm_writes?
  end

  private
    def api_headers
      { "X-Api-Key" => @api_key.plain_key }
    end

    def propose(name:)
      result = PendingAssistantAction.propose!(
        chat: @chat,
        function: Assistant::Function::CreateTransaction.new(@user),
        arguments: { "account_id" => accounts(:depository).id, "date" => Date.current.iso8601, "amount" => 2500, "type" => "expense", "name" => name }
      )
      PendingAssistantAction.find(result[:pending_action_id])
    end
end
