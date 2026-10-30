# frozen_string_literal: true

# The household's own OpenAI-compatible LLM key ("bring your own key"). Any
# member can see whether one is set; only family admins can change or test it.
# The key itself is never returned, only its last four characters.
class Api::V1::AiSettingsController < Api::V1::BaseController
  before_action :ensure_read_scope, only: :show
  before_action :ensure_write_scope, :ensure_admin, only: %i[update destroy test_connection]

  def show
    render_settings
  end

  def update
    if family.update_llm_settings(**credential_params)
      render_settings
    else
      render json: {
        error: "validation_failed",
        message: family.errors.full_messages.to_sentence,
        errors: family.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    family.clear_llm_settings!
    render_settings
  end

  def test_connection
    response = family.test_llm_connection(**credential_params)

    if response.success?
      render json: { success: true, reply: response.data.to_s.truncate(200) }
    else
      render json: { success: false, error: "connection_failed", message: response.error&.message }, status: :unprocessable_entity
    end
  end

  private

    def family
      current_resource_owner.family
    end

    def render_settings
      @family = family
      @user = current_resource_owner
      render :show
    end

    # A named preset fills in whichever of base URL and model was left blank.
    def credential_params
      permitted = params.slice(:api_key, :base_url, :model, :preset).permit(:api_key, :base_url, :model, :preset)
      preset = Family::LLM_PRESETS[permitted[:preset].to_s] || {}

      {
        api_key: permitted[:api_key],
        uri_base: permitted[:base_url].presence || preset[:uri_base],
        model: permitted[:model].presence || preset[:model]
      }
    end

    def ensure_write_scope
      authorize_scope!(:write)
    end

    def ensure_admin
      return if current_resource_owner.admin?

      render json: { error: "forbidden", message: "Only a family admin can change the AI key" }, status: :forbidden
    end
end
