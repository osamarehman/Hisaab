Rails.application.configure do
  config.x.product_name = ENV["PRODUCT_NAME"].presence || "Hisaab"
  config.x.brand_name = ENV["BRAND_NAME"].presence

  # Named on the public privacy, terms and account-deletion pages.
  config.x.legal_publisher = ENV["LEGAL_PUBLISHER"].presence || "Usama Rehman"
  config.x.legal_contact_email = ENV["LEGAL_CONTACT_EMAIL"].presence || "osamarehmanmughal@gmail.com"

  # AGPL-3.0 requires offering the running code's source to its users.
  config.x.source_code_url = ENV["SOURCE_CODE_URL"].presence || "https://github.com/osamarehman/sure-redesign"
end
