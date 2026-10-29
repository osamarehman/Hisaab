# frozen_string_literal: true

# Waits for a statement attached in the chat to be read, then posts the
# assistant's batch of lines to confirm (Assistant::StatementProposal).
class AssistantStatementJob < ApplicationJob
  queue_as :default

  POLL_INTERVAL = 10.seconds
  MAX_ATTEMPTS = 36

  def perform(chat, import, file_name = nil, attempt = 1)
    proposal = Assistant::StatementProposal.new(chat: chat, import: import)
    return unless proposal.propose!(file_name: file_name) == :wait

    if attempt < MAX_ATTEMPTS
      self.class.set(wait: POLL_INTERVAL).perform_later(chat, import, file_name, attempt + 1)
    else
      chat.messages.create!(type: "AssistantMessage", content: I18n.t("assistant.statements.still_reading"), ai_model: Chat.default_model, status: "complete")
    end
  end
end
