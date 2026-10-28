# frozen_string_literal: true

require "test_helper"

class AssetLinksControllerTest < ActionDispatch::IntegrationTest
  UPLOAD_KEY = "05:5D:5B:82:1A:F1:8D:4B:BB:BA:0B:DB:1D:14:76:2B:1E:7A:09:DF:54:FA:47:53:E2:AA:73:1A:3B:8D:90:21"

  test "lets the Android app use this server's passkeys without signing in" do
    get "/.well-known/assetlinks.json"

    assert_response :success
    assert_equal "application/json", response.media_type

    statement = JSON.parse(response.body).sole
    assert_equal %w[delegate_permission/common.handle_all_urls delegate_permission/common.get_login_creds].sort,
      statement["relation"].sort
    assert_equal "android_app", statement.dig("target", "namespace")
    assert_equal "dev.shipdeck.hisaab", statement.dig("target", "package_name")
    assert_includes statement.dig("target", "sha256_cert_fingerprints"), UPLOAD_KEY
  end

  test "lists every configured signing certificate" do
    second = "AA:" * 31 + "BB"
    with_android_app(fingerprints: [ UPLOAD_KEY, second ]) do
      get "/.well-known/assetlinks.json"
    end

    assert_equal [ UPLOAD_KEY, second ], JSON.parse(response.body).sole.dig("target", "sha256_cert_fingerprints")
  end

  test "serves an empty statement list when no certificate is configured" do
    with_android_app(fingerprints: []) do
      get "/.well-known/assetlinks.json"
    end

    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end

  test "accepts WebAuthn requests from the app signed with the configured key" do
    digest = [ UPLOAD_KEY.delete(":") ].pack("H*")
    origin = "android:apk-key-hash:#{Base64.urlsafe_encode64(digest, padding: false)}"

    assert_includes Rails.application.config.x.webauthn.allowed_origins, origin
    assert_includes Rails.application.config.x.webauthn.allowed_origins, "http://www.example.com"
  end

  private
    def with_android_app(fingerprints:)
      config = Rails.application.config.x.android_app
      previous = config.sha256_cert_fingerprints
      config.sha256_cert_fingerprints = fingerprints
      yield
    ensure
      config.sha256_cert_fingerprints = previous
    end
end
