# frozen_string_literal: true

json.key_present @family.own_llm_key?
json.key_last4 @family.llm_key_last4
json.base_url @family.llm_uri_base
json.model @family.llm_model
json.preset @family.llm_preset
json.can_edit @user.admin?
json.ai_available @user.ai_available?
json.presets Family::LLM_PRESETS do |id, preset|
  json.id id
  json.base_url preset[:uri_base]
  json.model preset[:model]
end
