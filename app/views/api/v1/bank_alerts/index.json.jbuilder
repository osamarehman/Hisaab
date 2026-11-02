# frozen_string_literal: true

json.bank_alerts @alerts do |bank_alert|
  json.partial! "api/v1/bank_alerts/bank_alert", bank_alert: bank_alert
end

json.pagination do
  json.page @pagy.page
  json.per_page @per_page
  json.total_count @pagy.count
  json.total_pages @pagy.pages
end
