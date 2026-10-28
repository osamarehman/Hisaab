# frozen_string_literal: true

# Digital Asset Links statement that lets the Android app use this server's
# passkeys (Credential Manager checks it before any WebAuthn ceremony for this
# RP ID) and open its links. Configured in config/initializers/webauthn.rb.
class AssetLinksController < ApplicationController
  skip_authentication
  skip_before_action :verify_authenticity_token
  skip_before_action :require_onboarding_and_upgrade, raise: false
  skip_before_action :set_default_chat, raise: false
  skip_before_action :detect_os, raise: false

  def show
    android_app = Rails.application.config.x.android_app
    fingerprints = Array(android_app.sha256_cert_fingerprints)

    statements = if fingerprints.any?
      [
        {
          relation: %w[
            delegate_permission/common.handle_all_urls
            delegate_permission/common.get_login_creds
          ],
          target: {
            namespace: "android_app",
            package_name: android_app.package_name,
            sha256_cert_fingerprints: fingerprints
          }
        }
      ]
    else
      []
    end

    expires_in 1.hour, public: true
    render json: statements
  end
end
