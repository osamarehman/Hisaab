# frozen_string_literal: true

module WebauthnRelyingParty
  extend ActiveSupport::Concern

  private
    def webauthn_relying_party
      @webauthn_relying_party ||= WebauthnCredential.relying_party
    end

    def webauthn_registration_options_for(user, authenticator_selection:)
      user.ensure_webauthn_id!

      webauthn_relying_party.options_for_registration(
        user: { id: user.webauthn_id, name: user.email, display_name: user.display_name },
        exclude: user.webauthn_credentials.pluck(:credential_id),
        authenticator_selection: authenticator_selection,
        attestation: "none"
      )
    end

    def webauthn_credential_payload
      payload = params.require(:credential)
      payload = JSON.parse(payload) if payload.is_a?(String)

      payload = payload.to_unsafe_h if payload.respond_to?(:to_unsafe_h)
      raise ActionController::BadRequest, "credential must be an object" unless payload.is_a?(Hash)

      payload
    rescue JSON::ParserError, TypeError, ArgumentError
      raise ActionController::BadRequest, "invalid credential payload"
    end
end
