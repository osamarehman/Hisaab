# frozen_string_literal: true

# A household's own OpenAI-compatible LLM credentials ("bring your own key").
# The key is encrypted with Active Record encryption when it is configured.
class AddLlmSettingsToFamilies < ActiveRecord::Migration[8.1]
  def change
    add_column :families, :llm_api_key, :text
    add_column :families, :llm_uri_base, :string
    add_column :families, :llm_model, :string
  end
end
