class UserMessage < Message
  validates :ai_model, presence: true

  # Set for a message that only records something the user did (attaching a
  # statement), where the reply comes from elsewhere instead of the model.
  attribute :skip_assistant_response, :boolean, default: false

  after_create_commit :request_response_later, unless: :skip_assistant_response

  def role
    "user"
  end

  def request_response_later
    chat.ask_assistant_later(self)
  end

  def request_response(assistant_message: nil)
    chat.ask_assistant(self, assistant_message: assistant_message)
  end
end
