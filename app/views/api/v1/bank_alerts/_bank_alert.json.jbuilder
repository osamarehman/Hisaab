# frozen_string_literal: true

json.id bank_alert.id
json.status bank_alert.status
json.received_at bank_alert.received_at.iso8601
json.from bank_alert.from_address
json.sender_verified bank_alert.sender_verified
json.subject bank_alert.subject
json.parser bank_alert.parser
json.amount bank_alert.amount&.to_d&.to_s("F")
json.currency bank_alert.currency
json.direction bank_alert.direction
json.last4 bank_alert.last4
json.occurred_at bank_alert.occurred_at&.iso8601
json.payee bank_alert.payee
if bank_alert.account
  json.account { json.id bank_alert.account.id; json.name bank_alert.account.name }
else
  json.account nil
end
json.transaction_id bank_alert.entry_id
json.error bank_alert.error
