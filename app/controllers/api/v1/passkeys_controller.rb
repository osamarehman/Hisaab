# frozen_string_literal: true

module Api
  module V1
    # Passkeys of the signed-in user: list, register and remove.
    #
    # Registering is two calls. `POST /api/v1/passkeys/options` returns the
    # WebAuthn creation options for the device's passkey prompt, and
    # `POST /api/v1/passkeys` saves the credential the device produced. Both
    # take the step-up proof: the authenticator/backup `code` when the user has
    # two-factor authentication on, otherwise their `password`.
    class PasskeysController < BaseController
      include WebauthnRelyingParty

      before_action -> { authorize_scope!(:read) }, only: :index
      before_action -> { authorize_scope!(:write) }, only: %i[options create destroy]
      before_action :ensure_step_up_available, only: %i[options create]

      # Guessing the step-up through either call alone stays at 10 a minute.
      rate_limit to: 10, within: 1.minute, by: -> { current_resource_owner.id }, only: :options, name: "passkey-step-up-check",
        with: -> { render json: { error: I18n.t("webauthn_credentials.rate_limited") }, status: :too_many_requests }
      rate_limit to: 10, within: 1.minute, by: -> { current_resource_owner.id }, only: :create, name: "passkey-step-up-spend",
        with: -> { render json: { error: I18n.t("webauthn_credentials.rate_limited") }, status: :too_many_requests }

      def index
        passkeys = current_resource_owner.webauthn_credentials.order(:created_at)
        render json: {
          passkeys: passkeys.map { |passkey| passkey_json(passkey) },
          step_up: step_up_kind
        }
      end

      def options
        status = current_resource_owner.passkey_step_up_status(**step_up_params)
        return render_step_up_error(status) unless status == :accepted

        # Passkeys from the app are for passwordless sign-in, so the credential
        # must be discoverable and the device must verify the user.
        options = webauthn_registration_options_for(
          current_resource_owner,
          authenticator_selection: {
            resident_key: "required",
            require_resident_key: true,
            user_verification: "required"
          }
        )
        WebauthnChallenge.issue!(:api_registration, options.challenge, scope: current_resource_owner.id)

        render json: options
      end

      def create
        challenge = params[:challenge].to_s
        unless WebauthnChallenge.consume!(:api_registration, challenge, scope: current_resource_owner.id)
          return render_failure
        end

        payload = webauthn_credential_payload
        credential = webauthn_relying_party.verify_registration(
          payload,
          challenge,
          user_presence: true,
          user_verification: true
        )

        # The step-up is spent in the same transaction as the save, so a failed
        # save never uses up a single-use code.
        passkey = nil
        status = nil
        current_resource_owner.transaction do
          status = current_resource_owner.verify_passkey_step_up(**step_up_params)
          raise ActiveRecord::Rollback unless status == :accepted

          passkey = current_resource_owner.add_webauthn_credential!(
            credential,
            nickname: params[:nickname],
            transports: Array(payload.dig("response", "transports"))
          )
        end

        return render_step_up_error(status) unless status == :accepted

        render json: passkey_json(passkey), status: :created
      rescue WebAuthn::Error, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique, ActionController::BadRequest
        render_failure
      end

      def destroy
        current_resource_owner.webauthn_credentials.find(params[:id]).destroy!
        head :no_content
      end

      private
        def ensure_step_up_available
          return if current_resource_owner.passkey_step_up_available?

          render json: { error: I18n.t("webauthn_credentials.mfa_required") }, status: :forbidden
        end

        # What adding a passkey asks for, so the app shows the right field.
        def step_up_kind
          user = current_resource_owner
          return "code" if user.otp_required?
          return "password" if user.has_local_password?

          nil
        end

        def step_up_params
          { code: params[:code], password: params[:password] }
        end

        def render_step_up_error(status)
          key = if status == :replayed
            "webauthn_credentials.code_already_used"
          elsif current_resource_owner.otp_required?
            "webauthn_credentials.invalid_code"
          else
            "webauthn_credentials.invalid_password"
          end

          render json: { error: I18n.t(key), mfa_required: current_resource_owner.otp_required? }, status: :unprocessable_entity
        end

        def render_failure
          render json: { error: I18n.t("webauthn_credentials.failure") }, status: :unprocessable_entity
        end

        def passkey_json(passkey)
          {
            id: passkey.id,
            nickname: passkey.nickname,
            created_at: passkey.created_at.iso8601,
            last_used_at: passkey.last_used_at&.iso8601
          }
        end
    end
  end
end
