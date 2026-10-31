# A household's own OpenAI-compatible LLM credentials ("bring your own key").
#
# When a family stores a key, every AI feature it uses (assistant chat,
# auto-categorization, merchant detection, PDF reading, voice notes) runs on
# that key, base URL and model instead of the server's. Without one, the
# server-wide configuration applies exactly as before.
module Family::LlmConfigurable
  extend ActiveSupport::Concern

  # Prefill values for the settings screen. The model stays editable.
  LLM_PRESETS = {
    "gemini" => { uri_base: "https://generativelanguage.googleapis.com/v1beta/openai/", model: "gemini-2.5-flash" },
    "openrouter" => { uri_base: "https://openrouter.ai/api/v1", model: "meta-llama/llama-3.3-70b-instruct:free" },
    "groq" => { uri_base: "https://api.groq.com/openai/v1", model: "llama-3.3-70b-versatile" }
  }.freeze

  # Hosts a family may point its key at in production. A fixed list rather
  # than a DNS check, because the server resolves the name again for every
  # request and a check made once at save time can be rebound to an internal
  # address. LLM_ALLOWED_HOSTS (comma-separated) adds more.
  LLM_DEFAULT_HOSTS = %w[
    generativelanguage.googleapis.com openrouter.ai api.groq.com api.openai.com
    api.mistral.ai api.deepseek.com api.together.xyz api.cerebras.ai
  ].freeze

  def self.allowed_llm_hosts
    LLM_DEFAULT_HOSTS | ENV.fetch("LLM_ALLOWED_HOSTS", "").split(",").map { |host| host.strip.downcase }.reject(&:empty?)
  end

  # A connection test is one tiny completion; it should fail fast rather
  # than hold a request thread for the full chat timeout.
  LLM_TEST_TIMEOUT = 15

  included do
    include Encryptable

    encrypts :llm_api_key if encryption_ready?

    normalizes :llm_api_key, :llm_uri_base, :llm_model, with: ->(value) { value.to_s.strip.presence }

    validates :llm_uri_base, :llm_model, presence: true, if: :own_llm_key?
    validates :llm_api_key, :llm_uri_base, :llm_model, length: { maximum: 2048 }
    validate :llm_uri_base_must_be_reachable_safely, if: :llm_uri_base_changed?
  end

  def own_llm_key?
    llm_api_key.present?
  end

  # Provider built from the family's own credentials, or nil without a key.
  def own_llm_provider(request_timeout: nil)
    return unless own_llm_key?

    Provider::Openai.new(
      llm_api_key,
      uri_base: llm_uri_base,
      model: llm_model,
      server_overrides: false,
      request_timeout: request_timeout
    )
  end

  def llm_key_last4
    llm_api_key.last(4) if own_llm_key?
  end

  # Which preset the stored base URL matches, for the settings screen.
  def llm_preset
    return if llm_uri_base.blank?

    normalized = llm_uri_base.chomp("/")
    LLM_PRESETS.find { |_name, preset| preset[:uri_base].chomp("/") == normalized }&.first || "custom"
  end

  # Saves the family's credentials. A blank key keeps the stored one, so the
  # model or URL can be changed without pasting the key again.
  def update_llm_settings(api_key:, uri_base:, model:)
    self.llm_api_key = api_key if api_key.present?
    self.llm_uri_base = uri_base
    self.llm_model = model

    unless own_llm_key?
      errors.add(:llm_api_key, :blank)
      return false
    end

    save
  end

  def clear_llm_settings!
    update!(llm_api_key: nil, llm_uri_base: nil, llm_model: nil)
  end

  # One short completion against the given (or stored) credentials, so a key
  # can be checked before it is saved. Returns a Provider::Response whose error
  # message is the provider's own explanation when it rejects the call.
  def test_llm_connection(api_key: nil, uri_base: nil, model: nil)
    candidate = Family.new(
      llm_api_key: api_key.presence || llm_api_key,
      llm_uri_base: uri_base.presence || llm_uri_base,
      llm_model: model.presence || llm_model
    )
    candidate.validate
    messages = candidate.errors.select { |error| error.attribute.to_s.start_with?("llm_") }.map(&:full_message)
    messages.unshift(candidate.errors.full_message(:llm_api_key, I18n.t("errors.messages.blank"))) unless candidate.own_llm_key?

    if messages.any?
      return Provider::Response.new(success?: false, data: nil, error: Provider::Error.new(messages.uniq.to_sentence))
    end

    candidate.own_llm_provider(request_timeout: LLM_TEST_TIMEOUT).test_connection
  end

  private
    # The server makes these requests, so the URL must be https and, in
    # production, must not resolve into the server's own network. Plain http
    # is accepted only for a local model outside production.
    def llm_uri_base_must_be_reachable_safely
      return if llm_uri_base.blank?

      uri = URI.parse(llm_uri_base)
      return if local_development_uri?(uri)
      return errors.add(:llm_uri_base, :insecure) unless uri.is_a?(URI::HTTPS) && uri.host.present?
      return unless Rails.env.production?

      errors.add(:llm_uri_base, :not_allowed) unless uri.hostname.downcase.in?(Family::LlmConfigurable.allowed_llm_hosts)
    rescue URI::InvalidURIError
      errors.add(:llm_uri_base, :invalid)
    end

    def local_development_uri?(uri)
      !Rails.env.production? && uri.instance_of?(URI::HTTP) && uri.hostname.in?(%w[localhost 127.0.0.1 ::1])
    end
end
