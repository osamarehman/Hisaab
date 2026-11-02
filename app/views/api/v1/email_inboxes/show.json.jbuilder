# frozen_string_literal: true

json.address @inbox.address
json.rotated_at @inbox.rotated_at.iso8601
if @inbox.confirmation_received_at
  json.confirmation do
    json.code @inbox.confirmation_code
    json.url @inbox.confirmation_url
    json.received_at @inbox.confirmation_received_at.iso8601
  end
else
  json.confirmation nil
end
json.senders @senders, partial: "api/v1/email_senders/email_sender", as: :email_sender
json.recent @alerts, partial: "api/v1/bank_alerts/bank_alert", as: :bank_alert
