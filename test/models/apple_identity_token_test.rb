# frozen_string_literal: true

require "test_helper"
require Rails.root.join("test/support/apple_identity_token_test_helper").to_s

class AppleIdentityTokenTest < ActiveSupport::TestCase
  include AppleIdentityTokenTestHelper

  setup do
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    stub_apple_keys
  end

  teardown do
    Rails.cache = @original_cache
  end

  test "accepts a token Apple signed for this app and nonce" do
    token = AppleIdentityToken.verify!(apple_identity_token(nonce: "n-1"), nonce: "n-1", client_ids: [ "dev.shipdeck.hisaab" ])

    assert_equal "001234.apple-user", token.subject
    assert_equal "apple-user@privaterelay.appleid.com", token.email
  end

  test "rejects a token replayed with a different nonce" do
    assert_raises(AppleIdentityToken::InvalidError) do
      AppleIdentityToken.verify!(apple_identity_token(nonce: "n-1"), nonce: "n-2", client_ids: [ "dev.shipdeck.hisaab" ])
    end
  end

  test "rejects a token issued for another app" do
    assert_raises(AppleIdentityToken::InvalidError) do
      AppleIdentityToken.verify!(apple_identity_token(nonce: "n", aud: "com.example.other"), nonce: "n", client_ids: [ "dev.shipdeck.hisaab" ])
    end
  end

  test "rejects a token not issued by Apple" do
    assert_raises(AppleIdentityToken::InvalidError) do
      AppleIdentityToken.verify!(apple_identity_token(nonce: "n", iss: "https://evil.example"), nonce: "n", client_ids: [ "dev.shipdeck.hisaab" ])
    end
  end

  test "rejects an expired token" do
    assert_raises(AppleIdentityToken::InvalidError) do
      AppleIdentityToken.verify!(apple_identity_token(nonce: "n", exp: 1.minute.ago), nonce: "n", client_ids: [ "dev.shipdeck.hisaab" ])
    end
  end

  test "rejects a token signed with someone else's key" do
    forged = apple_identity_token(nonce: "n", key: OpenSSL::PKey::RSA.generate(2048))

    assert_raises(AppleIdentityToken::InvalidError) do
      AppleIdentityToken.verify!(forged, nonce: "n", client_ids: [ "dev.shipdeck.hisaab" ])
    end
  end

  test "rejects every token when no bundle ID is configured" do
    assert_raises(AppleIdentityToken::InvalidError) do
      AppleIdentityToken.verify!(apple_identity_token(nonce: "n"), nonce: "n", client_ids: [])
    end
  end

  test "reports Apple's key endpoint being down as an invalid token" do
    stub_request(:get, AppleIdentityToken::KEYS_URL.to_s).to_return(status: 503)

    assert_raises(AppleIdentityToken::InvalidError) do
      AppleIdentityToken.verify!(apple_identity_token(nonce: "n"), nonce: "n", client_ids: [ "dev.shipdeck.hisaab" ])
    end
  end
end
