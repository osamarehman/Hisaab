# frozen_string_literal: true

# Signs Sign in with Apple identity tokens with a test key and serves that key
# from Apple's (stubbed) JWKS endpoint.
module AppleIdentityTokenTestHelper
  APPLE_TEST_KEY = OpenSSL::PKey::RSA.generate(2048)
  APPLE_TEST_KID = "apple-test-key"

  def stub_apple_keys
    jwk = JWT::JWK.new(APPLE_TEST_KEY, kid: APPLE_TEST_KID)
    stub_request(:get, AppleIdentityToken::KEYS_URL.to_s)
      .to_return(status: 200, body: { keys: [ jwk.export ] }.to_json, headers: { "Content-Type" => "application/json" })
  end

  def apple_identity_token(nonce:, sub: "001234.apple-user", email: "apple-user@privaterelay.appleid.com",
                           aud: "dev.shipdeck.hisaab", iss: AppleIdentityToken::ISSUER, exp: 10.minutes.from_now,
                           key: APPLE_TEST_KEY)
    payload = {
      iss: iss,
      aud: aud,
      sub: sub,
      exp: exp.to_i,
      iat: Time.current.to_i,
      nonce: Digest::SHA256.hexdigest(nonce),
      email: email,
      email_verified: "true"
    }.compact
    JWT.encode(payload, key, "RS256", kid: APPLE_TEST_KID)
  end
end
