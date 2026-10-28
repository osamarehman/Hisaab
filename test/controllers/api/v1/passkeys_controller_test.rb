# frozen_string_literal: true

require "test_helper"
require "webauthn/fake_client"

class Api::V1::PasskeysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    @user.webauthn_credentials.destroy_all
    @user.disable_mfa! if @user.otp_required?

    @user.api_keys.active.destroy_all
    @read_key = create_api_key(@user, "read")
    @write_key = create_api_key(@user, "read_write")

    @client = WebAuthn::FakeClient.new("http://www.example.com")

    # Challenges for API clients live in the cache; test env uses :null_store.
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @original_cache
  end

  test "index requires authentication" do
    get api_v1_passkeys_url

    assert_response :unauthorized
  end

  test "index lists the user's passkeys and the step-up they need" do
    @user.webauthn_credentials.create!(nickname: "Pixel", credential_id: "cred-1", public_key: "key", sign_count: 0)

    get api_v1_passkeys_url, headers: api_headers(@read_key)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "password", body["step_up"]
    assert_equal [ "Pixel" ], body["passkeys"].map { |passkey| passkey["nickname"] }
    assert body["passkeys"].first["created_at"].present?
  end

  test "a read-only key cannot register a passkey" do
    post options_api_v1_passkeys_url, params: { password: user_password_test }, headers: api_headers(@read_key), as: :json

    assert_response :forbidden
  end

  test "registers a discoverable passkey after confirming the password" do
    options = registration_options(password: user_password_test)
    assert_equal "required", options.dig("authenticatorSelection", "residentKey")
    assert_equal "required", options.dig("authenticatorSelection", "userVerification")

    credential = @client.create(challenge: options["challenge"], rp_id: "www.example.com", user_verified: true)

    assert_difference -> { @user.webauthn_credentials.count }, 1 do
      post api_v1_passkeys_url, params: {
        challenge: options["challenge"], credential: credential, nickname: "My phone", password: user_password_test
      }, headers: api_headers(@write_key), as: :json
    end

    assert_response :created
    assert_equal "My phone", JSON.parse(response.body)["nickname"]
    assert @user.reload.webauthn_id.present?
  end

  test "accepts a registration from the Android app's signing origin" do
    android_origin = Rails.application.config.x.webauthn.allowed_origins.find { |origin| origin.start_with?("android:apk-key-hash:") }
    assert android_origin, "default Android signing origin is missing"

    options = registration_options(password: user_password_test)
    credential = WebAuthn::FakeClient.new(android_origin)
      .create(challenge: options["challenge"], rp_id: "www.example.com", user_verified: true)

    post api_v1_passkeys_url, params: { challenge: options["challenge"], credential: credential, password: user_password_test },
      headers: api_headers(@write_key), as: :json

    assert_response :created
  end

  test "refuses options for a wrong password" do
    post options_api_v1_passkeys_url, params: { password: "wrong" }, headers: api_headers(@write_key), as: :json

    assert_response :unprocessable_entity
    assert_equal I18n.t("webauthn_credentials.invalid_password"), JSON.parse(response.body)["error"]
  end

  test "asks for the authenticator code when two-factor is on" do
    @user.setup_mfa!
    codes = @user.enable_mfa!

    post options_api_v1_passkeys_url, params: { password: user_password_test }, headers: api_headers(@write_key), as: :json
    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["mfa_required"]

    options = registration_options(code: codes.first)
    credential = @client.create(challenge: options["challenge"], rp_id: "www.example.com", user_verified: true)

    post api_v1_passkeys_url, params: { challenge: options["challenge"], credential: credential, code: codes.first },
      headers: api_headers(@write_key), as: :json

    assert_response :created
  end

  test "a registration challenge can only be used once" do
    options = registration_options(password: user_password_test)
    credential = @client.create(challenge: options["challenge"], rp_id: "www.example.com", user_verified: true)
    params = { challenge: options["challenge"], credential: credential, password: user_password_test }

    post api_v1_passkeys_url, params: params, headers: api_headers(@write_key), as: :json
    assert_response :created

    post api_v1_passkeys_url, params: params, headers: api_headers(@write_key), as: :json
    assert_response :unprocessable_entity
  end

  test "rejects a registration without user verification" do
    options = registration_options(password: user_password_test)
    credential = @client.create(challenge: options["challenge"], rp_id: "www.example.com", user_verified: false)

    assert_no_difference -> { WebauthnCredential.count } do
      post api_v1_passkeys_url, params: { challenge: options["challenge"], credential: credential, password: user_password_test },
        headers: api_headers(@write_key), as: :json
    end

    assert_response :unprocessable_entity
  end

  test "rejects a challenge issued to another user" do
    other_user = users(:family_member)
    other_user.api_keys.active.destroy_all
    other_key = create_api_key(other_user, "read_write")
    options = registration_options(password: user_password_test)
    credential = @client.create(challenge: options["challenge"], rp_id: "www.example.com", user_verified: true)

    post api_v1_passkeys_url, params: { challenge: options["challenge"], credential: credential, password: user_password_test },
      headers: api_headers(other_key), as: :json

    assert_response :unprocessable_entity
  end

  test "deletes only the user's own passkey" do
    mine = @user.webauthn_credentials.create!(nickname: "Mine", credential_id: "cred-mine", public_key: "key", sign_count: 0)
    theirs = users(:family_member).webauthn_credentials.create!(nickname: "Theirs", credential_id: "cred-theirs", public_key: "key", sign_count: 0)

    delete api_v1_passkey_url(theirs), headers: api_headers(@write_key)
    assert_response :not_found

    delete api_v1_passkey_url(mine), headers: api_headers(@write_key)
    assert_response :no_content
    assert_not WebauthnCredential.exists?(mine.id)
    assert WebauthnCredential.exists?(theirs.id)
  end

  private
    def create_api_key(user, scope)
      # One active key per source, so the read and read-write keys differ.
      source = scope == "read" ? "mobile" : "web"
      ApiKey.create!(user: user, name: "Passkeys #{scope}", scopes: [ scope ], source: source,
        display_key: "passkeys_#{scope}_#{SecureRandom.hex(8)}")
    end

    def api_headers(api_key)
      { "X-Api-Key" => api_key.display_key }
    end

    def registration_options(**step_up)
      post options_api_v1_passkeys_url, params: step_up, headers: api_headers(@write_key), as: :json
      assert_response :success
      JSON.parse(response.body)
    end
end
