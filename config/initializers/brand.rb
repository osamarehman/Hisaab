Rails.application.configure do
  config.x.product_name = ENV["PRODUCT_NAME"].presence || "Hisaab"
  config.x.brand_name = ENV["BRAND_NAME"].presence
end
