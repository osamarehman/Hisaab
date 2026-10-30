# frozen_string_literal: true

# Apple App Site Association file that lets the iOS app use this server's
# passkeys (iOS checks webcredentials before any WebAuthn ceremony for this
# RP ID). Configured in config/initializers/webauthn.rb.
class AppleAppSiteAssociationController < ApplicationController
  skip_authentication
  skip_before_action :verify_authenticity_token
  skip_before_action :require_onboarding_and_upgrade, raise: false
  skip_before_action :set_default_chat, raise: false
  skip_before_action :detect_os, raise: false

  def show
    expires_in 1.hour, public: true
    render json: { webcredentials: { apps: Array(Rails.application.config.x.ios_app.app_ids) } }
  end
end
