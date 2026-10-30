module Assistant::Provided
  extend ActiveSupport::Concern

  # A family with its own key always chats through it (a custom endpoint
  # serves any model name); otherwise the server's providers are tried in the
  # configured order.
  def get_model_provider(ai_model)
    own_provider = chat&.user&.family&.own_llm_provider
    return own_provider if own_provider

    Provider::Registry.llm_provider_order.each do |name|
      provider = Provider::Registry.get_provider(name)
      return provider if provider&.supports_model?(ai_model)
    end
    nil
  end

  private
    def registry
      @registry ||= Provider::Registry.for_concept(:llm)
    end
end
