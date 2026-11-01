# frozen_string_literal: true

# Verifies the identity token the iOS app gets from native Sign in with Apple:
# Apple's signature (keys from appleid.apple.com, cached), issuer, audience
# (the app's bundle ID) and the nonce the app sent to Apple as a SHA-256 hex
# digest, which binds the token to this sign-in attempt.
class AppleIdentityToken
  PROVIDER = "apple"
  ISSUER = "https://appleid.apple.com"
  KEYS_URL = URI("https://appleid.apple.com/auth/keys")
  KEYS_CACHE_KEY = "apple_sign_in/jwks"
  KEYS_REFETCH_KEY = "apple_sign_in/jwks_refetched"
  KEYS_REFETCH_COOLDOWN = 5.minutes

  class InvalidError < StandardError; end

  attr_reader :claims

  def self.verify!(token, nonce:, client_ids: Rails.configuration.x.auth.apple_client_ids)
    new(token, nonce: nonce, client_ids: Array(client_ids)).tap(&:verify!)
  end

  def self.jwks(options = {})
    # An unknown key ID usually means Apple rotated its keys. Refetch at most
    # once per cooldown, so tokens with made-up key IDs can't make every
    # request call Apple.
    if options[:kid_not_found] && Rails.cache.write(KEYS_REFETCH_KEY, true, expires_in: KEYS_REFETCH_COOLDOWN, unless_exist: true)
      Rails.cache.delete(KEYS_CACHE_KEY)
    end
    Rails.cache.fetch(KEYS_CACHE_KEY, expires_in: 12.hours) { fetch_jwks }
  end

  def self.fetch_jwks
    response = Net::HTTP.start(KEYS_URL.host, KEYS_URL.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
      http.get(KEYS_URL.request_uri)
    end
    raise InvalidError, "Apple keys unavailable (HTTP #{response.code})" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).slice("keys")
  rescue JSON::ParserError, SocketError, SystemCallError, Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError => e
    raise InvalidError, "Apple keys unavailable: #{e.class}"
  end

  def initialize(token, nonce:, client_ids:)
    @token = token.to_s
    @nonce = nonce.to_s
    @client_ids = client_ids.map(&:to_s).reject(&:blank?)
  end

  def verify!
    raise InvalidError, "Sign in with Apple is not configured" if @client_ids.empty?
    raise InvalidError, "Missing identity token or nonce" if @token.blank? || @nonce.blank?

    @claims, = JWT.decode(
      @token, nil, true,
      algorithms: [ "RS256" ],
      jwks: ->(options) { self.class.jwks(options) },
      iss: ISSUER, verify_iss: true,
      aud: @client_ids, verify_aud: true
    )

    expected_nonce = Digest::SHA256.hexdigest(@nonce)
    unless ActiveSupport::SecurityUtils.secure_compare(@claims["nonce"].to_s, expected_nonce)
      raise InvalidError, "Nonce mismatch"
    end
    raise InvalidError, "Missing subject" if subject.blank?

    self
  rescue JWT::DecodeError => e
    raise InvalidError, e.message
  end

  def subject
    claims["sub"].to_s
  end

  # Apple only puts a verified address (real or private relay) in the token.
  def email
    claims["email"].presence if ActiveModel::Type::Boolean.new.cast(claims["email_verified"])
  end
end
