# frozen_string_literal: true

require "test_helper"
require "webauthn/fake_client"

class Api::V1::AuthPasskeyLoginTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    @user.webauthn_credentials.destroy_all
    @user.disable_mfa! if @user.otp_required?
    @device_info = {
      device_id: "passkey-device-1",
      device_name: "Pixel 8",
      device_type: "android",
      os_version: "15",
      app_version: "1.0.0"
    }

    shared_app = Doorkeeper::Application.find_or_create_by!(name: "Sure Mobile") do |app|
      app.redirect_uri = "sureapp://oauth/callback"
      app.scopes = "read read_write"
      app.confidential = false
    end
    shared_app.update!(scopes: "read read_write")
    MobileDevice.instance_variable_set(:@shared_oauth_application, nil)

    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    @client = WebAuthn::FakeClient.new("http://www.example.com")
    @user.ensure_webauthn_id!
    challenge = WebAuthn.standard_encoder.encode(SecureRandom.random_bytes(32))
    created = WebauthnCredential.relying_party.verify_registration(
      @client.create(challenge: challenge, rp_id: "www.example.com", user_verified: true),
      challenge,
      user_verification: true
    )
    @stored_credential = @user.add_webauthn_credential!(created, nickname: "Pixel")
  end

  teardown do
    Rails.cache = @original_cache
  end

  test "signs in with a passkey and returns mobile tokens" do
    assert_difference -> { Doorkeeper::AccessToken.count }, 1 do
      post "/api/v1/auth/passkey/login", params: login_params, as: :json
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert body["access_token"].present?
    assert body["refresh_token"].present?
    assert_equal @user.id, body.dig("user", "id")
    assert @stored_credential.reload.last_used_at.present?
  end

  test "a passkey satisfies two-factor authentication" do
    @user.setup_mfa!
    @user.enable_mfa!

    post "/api/v1/auth/passkey/login", params: login_params, as: :json

    assert_response :success
  end

  test "options ask the device to verify the user" do
    post "/api/v1/auth/passkey/options", as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body["challenge"].present?
    assert_equal "www.example.com", body["rpId"]
    assert_equal "required", body["userVerification"]
  end

  test "a challenge can only be used once" do
    params = login_params

    post "/api/v1/auth/passkey/login", params: params, as: :json
    assert_response :success

    post "/api/v1/auth/passkey/login", params: params, as: :json
    assert_response :unauthorized
  end

  test "rejects a challenge the server never issued" do
    challenge = WebAuthn.standard_encoder.encode(SecureRandom.random_bytes(32))
    assertion = @client.get(challenge: challenge, rp_id: "www.example.com", user_verified: true, user_handle: raw_user_handle)

    post "/api/v1/auth/passkey/login", params: { challenge: challenge, credential: assertion, device: @device_info }, as: :json

    assert_response :unauthorized
  end

  test "rejects an assertion without user verification" do
    post "/api/v1/auth/passkey/login", params: login_params(user_verified: false), as: :json

    assert_response :unauthorized
    assert_nil @stored_credential.reload.last_used_at
  end

  test "rejects a deactivated user" do
    @user.update_column(:active, false)

    post "/api/v1/auth/passkey/login", params: login_params, as: :json

    assert_response :unauthorized
  end

  test "requires device information" do
    post "/api/v1/auth/passkey/login", params: login_params.except(:device), as: :json

    assert_response :bad_request
  end

  test "is refused when passkey sign-in is turned off" do
    AuthConfig.stubs(:passkey_login_enabled?).returns(false)

    post "/api/v1/auth/passkey/options", as: :json
    assert_response :forbidden

    post "/api/v1/auth/passkey/login", params: { challenge: "x", credential: {}, device: @device_info }, as: :json
    assert_response :forbidden
  end

  private
    def login_params(user_verified: true)
      post "/api/v1/auth/passkey/options", as: :json
      challenge = JSON.parse(response.body).fetch("challenge")

      assertion = @client.get(challenge: challenge, rp_id: "www.example.com", user_verified: user_verified, user_handle: raw_user_handle)
      { challenge: challenge, credential: assertion, device: @device_info }
    end

    def raw_user_handle
      WebAuthn.standard_encoder.decode(@user.webauthn_id)
    end
end
