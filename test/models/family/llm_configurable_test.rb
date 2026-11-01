require "test_helper"

class Family::LlmConfigurableTest < ActiveSupport::TestCase
  GROQ = Family::LLM_PRESETS.fetch("groq")

  setup do
    @family = families(:dylan_family)
  end

  test "saves credentials and reports the preset and last four characters" do
    assert @family.update_llm_settings(api_key: " gsk_test_abcd1234 ", uri_base: GROQ[:uri_base], model: GROQ[:model])

    @family.reload
    assert @family.own_llm_key?
    assert_equal "gsk_test_abcd1234", @family.llm_api_key
    assert_equal "1234", @family.llm_key_last4
    assert_equal "groq", @family.llm_preset
  end

  test "a blank key keeps the stored one" do
    @family.update_llm_settings(api_key: "gsk_test_abcd1234", uri_base: GROQ[:uri_base], model: GROQ[:model])

    assert @family.update_llm_settings(api_key: "", uri_base: GROQ[:uri_base], model: "llama-3.1-8b-instant")
    assert_equal "gsk_test_abcd1234", @family.reload.llm_api_key
    assert_equal "llama-3.1-8b-instant", @family.llm_model
  end

  test "requires a key, base URL and model" do
    assert_not @family.update_llm_settings(api_key: "", uri_base: GROQ[:uri_base], model: GROQ[:model])
    assert @family.errors.of_kind?(:llm_api_key, :blank)

    assert_not @family.update_llm_settings(api_key: "key", uri_base: "", model: "")
    assert @family.errors.of_kind?(:llm_uri_base, :blank)
    assert @family.errors.of_kind?(:llm_model, :blank)
  end

  test "rejects a plain http base URL except a local one outside production" do
    @family.assign_attributes(llm_api_key: "key", llm_model: "m", llm_uri_base: "http://example.com/v1")
    assert_not @family.valid?
    assert @family.errors.of_kind?(:llm_uri_base, :insecure)

    @family.llm_uri_base = "http://localhost:11434/v1"
    assert @family.valid?
  end

  test "accepts only known AI provider hosts in production" do
    Rails.env.stubs(:production?).returns(true)
    Addrinfo.expects(:getaddrinfo).never

    @family.assign_attributes(llm_api_key: "key", llm_model: "m", llm_uri_base: "https://internal.example.com/v1")
    assert_not @family.valid?
    assert @family.errors.of_kind?(:llm_uri_base, :not_allowed)

    @family.llm_uri_base = GROQ[:uri_base]
    assert @family.valid?

    @family.llm_uri_base = "http://localhost:11434/v1"
    assert_not @family.valid?
    assert @family.errors.of_kind?(:llm_uri_base, :insecure)
  end

  test "LLM_ALLOWED_HOSTS adds hosts in production" do
    Rails.env.stubs(:production?).returns(true)
    @family.assign_attributes(llm_api_key: "key", llm_model: "m", llm_uri_base: "https://llm.example.com/v1")

    ClimateControl.modify(LLM_ALLOWED_HOSTS: " LLM.example.com ") { assert @family.valid? }
  end

  test "the base URL is only checked when it changes" do
    @family.update!(llm_api_key: "key", llm_model: "m", llm_uri_base: GROQ[:uri_base])
    @family.expects(:llm_uri_base_must_be_reachable_safely).never

    @family.update!(name: "Renamed")
  end

  test "an unknown base URL is a custom preset" do
    @family.llm_uri_base = "https://api.example.com/v1"
    assert_equal "custom", @family.llm_preset
  end

  test "the family's own key overrides the server's provider and model" do
    Setting.stubs(:openai_access_token).returns("server-token")
    Setting.stubs(:openai_model).returns("gpt-4.1")
    @family.update_llm_settings(api_key: "gsk_test", uri_base: GROQ[:uri_base], model: GROQ[:model])

    provider = @family.llm_provider
    assert_instance_of Provider::Openai, provider
    assert provider.custom_provider?
    assert_equal GROQ[:model], provider.default_model
    assert_not provider.supports_responses_endpoint?
    assert_equal GROQ[:model], Chat.default_model(@family)
    assert_equal GROQ[:model], @family.categorization_model_name
  end

  test "without its own key a family uses the server's provider" do
    Setting.stubs(:openai_access_token).returns("server-token")
    Setting.stubs(:openai_model).returns("gpt-4.1")
    Setting.stubs(:openai_uri_base).returns(nil)

    provider = @family.llm_provider
    assert_not provider.custom_provider?
    assert_equal Chat.default_model, Chat.default_model(@family)
  end

  test "an own key passes the AI email allowlist but does not unlock the server's Jev" do
    with_env_overrides(AI_ALLOWED_EMAILS: "someone-else@example.com") do
      assert_not @family.ai_allowed?

      @family.update_llm_settings(api_key: "gsk_test", uri_base: GROQ[:uri_base], model: GROQ[:model])
      assert @family.ai_allowed?
      assert_not @family.server_ai_allowed?

      Provider::Registry.expects(:get_provider).with(:jev).never
      @family.stubs(:effective_categorization_provider).returns("jev")
      assert_instance_of Provider::Openai, @family.resolved_categorization_provider
    end
  end

  test "an own key makes AI available on a self-hosted server without one" do
    Rails.application.config.app_mode.stubs(:self_hosted?).returns(true)
    Provider::Openai.stubs(:configured?).returns(false)
    Provider::Anthropic.stubs(:configured?).returns(false)
    user = users(:family_member)
    assert_not user.ai_available?

    @family.update_llm_settings(api_key: "gsk_test", uri_base: GROQ[:uri_base], model: GROQ[:model])
    assert user.reload.ai_available?
  end

  test "connection test reports success" do
    stub_request(:post, "https://api.groq.com/openai/v1/chat/completions")
      .with(headers: { "Authorization" => "Bearer gsk_test" })
      .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                 body: { choices: [ { message: { role: "assistant", content: "OK" } } ] }.to_json)

    response = @family.test_llm_connection(api_key: "gsk_test", uri_base: GROQ[:uri_base], model: GROQ[:model])

    assert response.success?
    assert_equal "OK", response.data
  end

  test "connection test surfaces the provider's error message" do
    stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions")
      .to_return(status: 400, headers: { "Content-Type" => "application/json" },
                 body: [ { error: { code: 400, message: "API key not valid. Please pass a valid API key." } } ].to_json)

    gemini = Family::LLM_PRESETS.fetch("gemini")
    response = @family.test_llm_connection(api_key: "bad", uri_base: gemini[:uri_base], model: gemini[:model])

    assert_not response.success?
    assert_equal "API key not valid. Please pass a valid API key.", response.error.message
  end

  test "connection test rejects invalid settings without calling out" do
    response = @family.test_llm_connection(api_key: "key", uri_base: "http://example.com", model: "m")

    assert_not response.success?
    assert_match "https", response.error.message
  end
end
