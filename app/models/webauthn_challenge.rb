# frozen_string_literal: true

# Single-use WebAuthn challenges for clients without a Rails session (the
# mobile API). The browser flows keep their challenge in the session instead.
#
# A challenge must be spendable exactly once: synced passkeys often report a
# signature counter of 0 forever, so the counter cannot catch a replayed
# assertion and the challenge is the only replay guard left.
class WebauthnChallenge
  TTL = 5.minutes

  class << self
    def issue!(purpose, challenge, scope: nil)
      Rails.cache.write(cache_key(purpose, challenge, scope), true, expires_in: TTL)
      challenge
    end

    # True only for the first caller holding a challenge this server issued
    # for the same purpose and scope.
    def consume!(purpose, challenge, scope: nil)
      return false if challenge.blank?

      Rails.cache.delete(cache_key(purpose, challenge, scope))
    end

    private
      def cache_key(purpose, challenge, scope)
        digest = Digest::SHA256.hexdigest(challenge.to_s)
        [ "webauthn_challenge", purpose, scope, digest ].compact.join(":")
      end
  end
end
