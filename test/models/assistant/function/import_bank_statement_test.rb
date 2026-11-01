require "test_helper"

class Assistant::Function::ImportBankStatementTest < ActiveSupport::TestCase
  setup do
    @user = users(:family_admin)
    @fn = Assistant::Function::ImportBankStatement.new(@user)
  end

  test "model_for falls back to Setting when OPENAI_MODEL env is blank" do
    Setting.stubs(:openai_model).returns("llama3")
    with_env_overrides("OPENAI_MODEL" => "") do
      assert_equal "llama3", @fn.send(:model_for, Provider::Openai.new("test-key"))
    end
  end

  test "model_for prefers OPENAI_MODEL env when set" do
    Setting.stubs(:openai_model).returns("llama3")
    with_env_overrides("OPENAI_MODEL" => "gpt-4o") do
      assert_equal "gpt-4o", @fn.send(:model_for, Provider::Openai.new("test-key"))
    end
  end

  test "model_for leaves non-OpenAI providers to their own default" do
    with_env_overrides("OPENAI_MODEL" => "gpt-4o") do
      assert_nil @fn.send(:model_for, Provider::Anthropic.new("test-key"))
    end
  end

  test "model_for uses the family's own model with its own key" do
    with_env_overrides("OPENAI_MODEL" => "gpt-4o") do
      provider = Provider::Openai.new("own-key", uri_base: "https://api.groq.com/openai/v1", model: "llama-3.3-70b-versatile", server_overrides: false)
      assert_equal "llama-3.3-70b-versatile", @fn.send(:model_for, provider)
    end
  end
end
