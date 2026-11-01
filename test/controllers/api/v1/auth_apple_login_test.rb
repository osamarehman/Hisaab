# frozen_string_literal: true

require "test_helper"
require Rails.root.join("test/support/apple_identity_token_test_helper").to_s

class Api::V1::AuthAppleLoginTest < ActionDispatch::IntegrationTest
  include AppleIdentityTokenTestHelper

  setup do
    @user = users(:family_admin)
    @user.disable_mfa! if @user.otp_required?
    @device_info = {
      device_id: "apple-device-1",
      device_name: "iPhone 17",
      device_type: "ios",
      os_version: "26.0",
      app_version: "1.0.3"
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
    stub_apple_keys
  end

  teardown do
    Rails.cache = @original_cache
  end

  test "signs in a linked Apple ID and returns mobile tokens" do
    OidcIdentity.create!(user: @user, provider: "apple", uid: "001234.apple-user", info: {})

    assert_difference -> { Doorkeeper::AccessToken.count }, 1 do
      post "/api/v1/auth/apple", params: apple_params, as: :json
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert body["access_token"].present?
    assert_equal @user.id, body.dig("user", "id")
  end

  test "hands an unlinked Apple ID a linking code that sso_create_account accepts" do
    post "/api/v1/auth/apple", params: apple_params(first_name: "Ayesha", last_name: "Khan"), as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "account_not_linked", body["status"]
    assert_equal "apple-user@privaterelay.appleid.com", body["email"]
    assert body["allow_account_creation"]

    assert_difference -> { User.count }, 1 do
      post "/api/v1/auth/sso_create_account", params: { linking_code: body["linking_code"] }, as: :json
    end

    assert_response :success
    created = User.find_by!(email: "apple-user@privaterelay.appleid.com")
    assert_equal "Ayesha", created.first_name
    assert OidcIdentity.exists?(user: created, provider: "apple", uid: "001234.apple-user")
  end

  test "rejects a token that fails verification" do
    post "/api/v1/auth/apple", params: apple_params(nonce: "wrong-nonce"), as: :json

    assert_response :unauthorized
    assert_no_match(/nonce/i, JSON.parse(response.body)["error"])
  end

  test "rejects an Apple ID an administrator removed" do
    SsoIdentityBlock.create!(provider: "apple", uid_digest: SsoIdentityBlock.digest("001234.apple-user"), identity_label: "removed")

    post "/api/v1/auth/apple", params: apple_params, as: :json

    assert_response :forbidden
  end

  test "requires device information" do
    post "/api/v1/auth/apple", params: apple_params.except(:device), as: :json

    assert_response :bad_request
  end

  test "is off when no bundle ID is configured" do
    Rails.configuration.x.auth.stubs(:apple_client_ids).returns([])

    post "/api/v1/auth/apple", params: apple_params, as: :json

    assert_response :forbidden
  end

  private
    def apple_params(nonce: "raw-nonce", **extra)
      {
        identity_token: apple_identity_token(nonce: "raw-nonce"),
        nonce: nonce,
        device: @device_info
      }.merge(extra)
    end
end
