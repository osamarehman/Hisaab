# frozen_string_literal: true

require "test_helper"

class AppleAppSiteAssociationControllerTest < ActionDispatch::IntegrationTest
  test "lets the iOS app use this server's passkeys without signing in" do
    get "/.well-known/apple-app-site-association"

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_equal [ "C8WT3YC922.dev.shipdeck.hisaab" ], JSON.parse(response.body).dig("webcredentials", "apps")
  end

  test "lists every configured app ID" do
    with_ios_app(app_ids: [ "C8WT3YC922.dev.shipdeck.hisaab", "ABCDE12345.dev.shipdeck.hisaab.beta" ]) do
      get "/.well-known/apple-app-site-association"
    end

    assert_equal [ "C8WT3YC922.dev.shipdeck.hisaab", "ABCDE12345.dev.shipdeck.hisaab.beta" ],
      JSON.parse(response.body).dig("webcredentials", "apps")
  end

  test "serves an empty app list when no app ID is configured" do
    with_ios_app(app_ids: []) do
      get "/.well-known/apple-app-site-association"
    end

    assert_response :success
    assert_equal [], JSON.parse(response.body).dig("webcredentials", "apps")
  end

  private
    def with_ios_app(app_ids:)
      config = Rails.application.config.x.ios_app
      previous = config.app_ids
      config.app_ids = app_ids
      yield
    ensure
      config.app_ids = previous
    end
end
