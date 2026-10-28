class Settings::WebauthnCredentialsController < ApplicationController
  include WebauthnRelyingParty

  layout "settings"

  before_action :ensure_step_up_available

  # Adding a passkey is confirmed with an MFA code, or the password when MFA is
  # off; keep a stolen session from guessing it. Both steps check it, so each
  # gets its own counter: guessing through either one alone stays at 10 a minute.
  rate_limit to: 10, within: 1.minute, by: -> { Current.user.id }, only: :options, name: "code-check",
    with: -> { render json: { error: t("webauthn_credentials.rate_limited") }, status: :too_many_requests }
  rate_limit to: 10, within: 1.minute, by: -> { Current.user.id }, only: :create, name: "code-spend",
    with: -> { render json: { error: t("webauthn_credentials.rate_limited") }, status: :too_many_requests }

  def options
    # Refuse a bad code before the browser runs its ceremony; otherwise the
    # authenticator keeps a discoverable passkey the server never saves.
    code_status = Current.user.passkey_step_up_status(**step_up_params)
    return render_code_error(code_status) unless code_status == :accepted

    registration_options = webauthn_registration_options_for(
      Current.user,
      # `resident_key: "preferred"` asks for a discoverable credential so the
      # key can also be used for passwordless sign-in. "preferred" rather than
      # "required" so authenticators without free resident-key slots (older
      # security keys) can still register as a second factor. User verification
      # stays "preferred" here for the same reason and is enforced as
      # "required" on the passwordless sign-in ceremony instead.
      authenticator_selection: { resident_key: "preferred", user_verification: "preferred" }
    )

    session[:webauthn_registration_challenge] = registration_options.challenge

    render json: registration_options
  end

  def create
    challenge = session.delete(:webauthn_registration_challenge)

    unless challenge.present?
      return render json: { error: t("webauthn_credentials.failure") }, status: :unprocessable_entity
    end

    credential = webauthn_relying_party.verify_registration(
      webauthn_credential_payload,
      challenge,
      user_presence: true
    )

    # A passkey is a lasting sign-in, so adding one must prove more than the
    # session cookie. The code is spent in the same transaction as the save, so
    # a registration that fails (or a cancelled browser prompt) never uses up a
    # single-use code.
    code_result = nil
    Current.user.transaction do
      code_result = Current.user.verify_passkey_step_up(**step_up_params)
      raise ActiveRecord::Rollback unless code_result == :accepted

      Current.user.add_webauthn_credential!(
        credential,
        nickname: webauthn_credential_name,
        transports: webauthn_credential_transports
      )
    end

    if code_result == :accepted
      render json: { redirect_url: settings_security_path }
    else
      render_code_error(code_result)
    end
  rescue WebAuthn::Error, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique, ActionController::BadRequest, ActionController::ParameterMissing
    render json: { error: t("webauthn_credentials.failure") }, status: :unprocessable_entity
  end

  def destroy
    Current.user.webauthn_credentials.find(params[:id]).destroy!
    redirect_to settings_security_path, notice: t("webauthn_credentials.success")
  end

  private
    def ensure_step_up_available
      return if Current.user.passkey_step_up_available?

      respond_to do |format|
        format.html { redirect_to settings_security_path, alert: t("webauthn_credentials.mfa_required") }
        format.json { render json: { error: t("webauthn_credentials.mfa_required") }, status: :forbidden }
      end
    end

    def webauthn_credential_name
      webauthn_credential_params[:nickname]
    end

    def webauthn_credential_transports
      Array(credential_response_params.dig(:response, :transports))
    end

    def step_up_params
      { code: webauthn_credential_params[:code], password: webauthn_credential_params[:password] }
    end

    def render_code_error(code_status)
      key = if code_status == :replayed
        "webauthn_credentials.code_already_used"
      elsif Current.user.otp_required?
        "webauthn_credentials.invalid_code"
      else
        "webauthn_credentials.invalid_password"
      end
      render json: { error: t(key) }, status: :unprocessable_entity
    end

    def webauthn_credential_params
      params.fetch(:webauthn_credential, ActionController::Parameters.new).permit(:nickname, :code, :password)
    end

    def credential_response_params
      params.fetch(:credential, ActionController::Parameters.new).permit(response: [ transports: [] ])
    end
end
