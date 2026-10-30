# frozen_string_literal: true

Rails.application.configure do
  config.x.webauthn = ActiveSupport::OrderedOptions.new

  credentials_config = Rails.application.credentials.webauthn || {}
  credential_rp_id = credentials_config[:rp_id] || credentials_config["rp_id"]
  credential_origins = credentials_config[:allowed_origins] || credentials_config["allowed_origins"]

  configured_rp_id = ENV["WEBAUTHN_RP_ID"].presence || credential_rp_id.presence || ENV["APP_DOMAIN"].presence
  default_rp_id = Rails.env.test? ? "www.example.com" : "localhost"

  rp_id = configured_rp_id.presence || default_rp_id
  rp_id = rp_id.to_s.strip.sub(%r{\Ahttps?://}, "").split("/").first.to_s.split(":").first

  configured_origins = ENV["WEBAUTHN_ALLOWED_ORIGINS"].presence || credential_origins
  allowed_origins = Array(configured_origins)
    .flat_map { |origin| origin.to_s.split(",") }
    .map { |origin| origin.strip.chomp("/") }
    .reject(&:blank?)

  if allowed_origins.blank?
    allowed_origins = if Rails.env.test?
      [ "http://www.example.com" ]
    elsif rp_id == "localhost"
      [ "http://localhost:3000" ]
    else
      [ "https://#{rp_id}" ]
    end
  end

  # The Android app signs its WebAuthn requests with the origin
  # "android:apk-key-hash:<base64url SHA-256 of the signing certificate>", and
  # Credential Manager only lets it use this RP ID once
  # /.well-known/assetlinks.json names the same package and certificates.
  # List every signing certificate in use (upload key, Play App Signing key,
  # debug keys for local builds) as colon-separated SHA-256 hex fingerprints.
  android_package = ENV["ANDROID_APP_PACKAGE_NAME"].presence || "dev.shipdeck.hisaab"
  android_fingerprints = (ENV["ANDROID_APP_SHA256_CERT_FINGERPRINTS"].presence ||
    "05:5D:5B:82:1A:F1:8D:4B:BB:BA:0B:DB:1D:14:76:2B:1E:7A:09:DF:54:FA:47:53:E2:AA:73:1A:3B:8D:90:21")
    .split(",")
    .map { |fingerprint| fingerprint.strip.upcase }
    .reject(&:empty?)
    .uniq
  malformed = android_fingerprints.reject { |fingerprint| fingerprint.match?(/\A(?:[0-9A-F]{2}:){31}[0-9A-F]{2}\z/) }
  if malformed.any?
    raise ArgumentError, "ANDROID_APP_SHA256_CERT_FINGERPRINTS has malformed entries: #{malformed.join(', ')}"
  end

  android_origins = android_fingerprints.map do |fingerprint|
    digest = [ fingerprint.delete(":") ].pack("H*")
    "android:apk-key-hash:#{Base64.urlsafe_encode64(digest, padding: false)}"
  end

  config.x.webauthn.rp_id = rp_id
  config.x.webauthn.allowed_origins = (allowed_origins + android_origins).uniq

  config.x.android_app = ActiveSupport::OrderedOptions.new
  config.x.android_app.package_name = android_package
  config.x.android_app.sha256_cert_fingerprints = android_fingerprints

  # The iOS app uses this RP ID for passkeys once
  # /.well-known/apple-app-site-association lists its App ID
  # ("<Team ID>.<bundle ID>") under webcredentials.
  ios_app_ids = (ENV["IOS_APP_IDS"].presence || "HM8BSRM7Y7.dev.shipdeck.hisaab")
    .split(",")
    .map(&:strip)
    .reject(&:empty?)
    .uniq
  malformed_ios = ios_app_ids.reject { |app_id| app_id.match?(/\A[A-Z0-9]{10}\.[A-Za-z0-9.-]+\z/) }
  if malformed_ios.any?
    raise ArgumentError, "IOS_APP_IDS has malformed entries: #{malformed_ios.join(', ')}"
  end

  config.x.ios_app = ActiveSupport::OrderedOptions.new
  config.x.ios_app.app_ids = ios_app_ids
end
