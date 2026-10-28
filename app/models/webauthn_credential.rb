class WebauthnCredential < ApplicationRecord
  belongs_to :user

  before_validation :set_default_nickname

  validates :nickname, presence: true, length: { maximum: 80 }
  validates :credential_id, presence: true, uniqueness: true
  validates :public_key, presence: true
  validates :sign_count, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  class << self
    def relying_party
      webauthn_config = Rails.application.config.x.webauthn

      WebAuthn::RelyingParty.new(
        name: Rails.configuration.x.product_name,
        id: webauthn_config.rp_id,
        allowed_origins: webauthn_config.allowed_origins,
        # Accept consumer passkeys/security keys without attesting device vendor
        # identity; this keeps MFA registration broad for self-hosted users.
        verify_attestation_statement: false
      )
    end

    # Signs in with a discoverable passkey ("usernameless" WebAuthn) and
    # returns its user, or nil. User verification is required, which makes the
    # passkey two factors on its own (possession + biometric/PIN), so callers
    # skip both the password and the TOTP step. Raises WebAuthn::Error when the
    # assertion does not verify.
    def authenticate_passkey(credential, challenge)
      # `presence` matters: `find_by(webauthn_id: nil)` would match every user
      # who never registered a credential.
      handle = credential.user_handle.presence
      return nil if handle.blank?

      user = User.find_by(webauthn_id: handle)
      return nil unless user&.active?
      return nil unless AuthConfig.local_login_allowed_for?(user)

      # Scoped to the user so an assertion can never pair one account's user
      # handle with another account's credential.
      stored_credential = user.webauthn_credentials.find_by(credential_id: credential.id)
      return nil unless stored_credential

      stored_credential.verify_assertion!(credential, challenge, user_verification: true)
      user
    end
  end

  def verify_assertion!(credential, challenge, user_verification:)
    with_lock do
      credential.verify(
        challenge,
        public_key: public_key,
        sign_count: sign_count,
        user_presence: true,
        user_verification: user_verification
      )

      update!(sign_count: credential.sign_count, last_used_at: Time.current)
    end
  end

  private
    def set_default_nickname
      self.nickname = nickname.to_s.strip.presence || I18n.t("webauthn_credentials.default_name")
    end
end
