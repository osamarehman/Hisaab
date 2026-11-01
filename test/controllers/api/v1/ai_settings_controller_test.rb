# frozen_string_literal: true

require "test_helper"

class Api::V1::AiSettingsControllerTest < ActionDispatch::IntegrationTest
  GEMINI = Family::LLM_PRESETS.fetch("gemini")

  setup do
    @admin = users(:family_admin)
    @member = users(:family_member)
    @family = @admin.family

    @admin.api_keys.active.destroy_all
    @member.api_keys.active.destroy_all
    @write_key = create_key(@admin, %w[read_write])
    @read_key = create_key(@admin, %w[read])
    @member_key = create_key(@member, %w[read_write])
  end

  test "shows that no key is set" do
    get api_v1_ai_settings_url, headers: api_headers(@read_key)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal false, body["key_present"]
    assert_nil body["key_last4"]
    assert_nil body["preset"]
    assert_equal true, body["can_edit"]
    assert_equal %w[gemini openrouter groq], body["presets"].map { |preset| preset["id"] }
  end

  test "saves a key from a preset and never returns it" do
    put api_v1_ai_settings_url, params: { preset: "gemini", api_key: "AIzaSecretKey9876" }, headers: api_headers(@write_key), as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal true, body["key_present"]
    assert_equal "9876", body["key_last4"]
    assert_equal "gemini", body["preset"]
    assert_equal GEMINI[:uri_base], body["base_url"]
    assert_equal GEMINI[:model], body["model"]
    assert_equal true, body["ai_available"]
    assert_not_includes response.body, "AIzaSecretKey9876"

    assert_equal "AIzaSecretKey9876", @family.reload.llm_api_key
  end

  test "rejects an insecure base URL" do
    put api_v1_ai_settings_url, params: { api_key: "key", base_url: "http://example.com/v1", model: "m" }, headers: api_headers(@write_key), as: :json

    assert_response :unprocessable_entity
    assert_equal "validation_failed", JSON.parse(response.body)["error"]
    assert_not @family.reload.own_llm_key?
  end

  test "rejects saving without a key" do
    put api_v1_ai_settings_url, params: { preset: "groq" }, headers: api_headers(@write_key), as: :json

    assert_response :unprocessable_entity
  end

  test "removes the key" do
    @family.update_llm_settings(api_key: "key", uri_base: GEMINI[:uri_base], model: GEMINI[:model])

    delete api_v1_ai_settings_url, headers: api_headers(@write_key)

    assert_response :success
    assert_equal false, JSON.parse(response.body)["key_present"]
    assert_not @family.reload.own_llm_key?
  end

  test "tests the connection" do
    stub_request(:post, "#{GEMINI[:uri_base]}chat/completions")
      .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                 body: { choices: [ { message: { content: "OK" } } ] }.to_json)

    post test_api_v1_ai_settings_url, params: { preset: "gemini", api_key: "key" }, headers: api_headers(@write_key), as: :json

    assert_response :success
    assert_equal({ "success" => true, "reply" => "OK" }, JSON.parse(response.body))
  end

  test "reports the provider's error when the connection test fails" do
    stub_request(:post, "#{GEMINI[:uri_base]}chat/completions")
      .to_return(status: 400, headers: { "Content-Type" => "application/json" },
                 body: [ { error: { message: "API key not valid." } } ].to_json)

    post test_api_v1_ai_settings_url, params: { preset: "gemini", api_key: "bad" }, headers: api_headers(@write_key), as: :json

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal false, body["success"]
    assert_equal "API key not valid.", body["message"]
  end

  test "members can read but not change the key" do
    get api_v1_ai_settings_url, headers: api_headers(@member_key)
    assert_response :success
    assert_equal false, JSON.parse(response.body)["can_edit"]

    put api_v1_ai_settings_url, params: { preset: "groq", api_key: "key" }, headers: api_headers(@member_key), as: :json
    assert_response :forbidden

    post test_api_v1_ai_settings_url, params: { preset: "groq", api_key: "key" }, headers: api_headers(@member_key), as: :json
    assert_response :forbidden

    delete api_v1_ai_settings_url, headers: api_headers(@member_key)
    assert_response :forbidden
  end

  test "a read-only key cannot change the key" do
    put api_v1_ai_settings_url, params: { preset: "groq", api_key: "key" }, headers: api_headers(@read_key), as: :json

    assert_response :forbidden
    assert_not @family.reload.own_llm_key?
  end

  test "requires authentication" do
    get api_v1_ai_settings_url

    assert_response :unauthorized
  end

  private

    def create_key(user, scopes)
      key = ApiKey.create!(
        user: user,
        name: "AI settings #{scopes.join}",
        scopes: scopes,
        source: scopes == %w[read] ? "mobile" : "web",
        display_key: "test_#{SecureRandom.hex(8)}"
      )
      Redis.new.del("api_rate_limit:#{key.id}")
      key
    end

    def api_headers(api_key)
      { "X-Api-Key" => api_key.plain_key }
    end
end
