# frozen_string_literal: true

json.message do
  json.partial! "api/v1/messages/message", message: @message
end
