# frozen_string_literal: true

# Any member can read the household's settings; only family admins can change
# them, the same rule the web preferences page applies to family attributes.
class Api::V1::FamilySettingsController < Api::V1::BaseController
  before_action :ensure_read_scope, only: :show
  before_action :ensure_write_scope, :ensure_admin, only: :update

  def show
    @family = current_resource_owner.family
  end

  def update
    @family = current_resource_owner.family
    currency = Family.normalize_currency_code(params[:currency])

    unless currency
      return render json: {
        error: "validation_failed",
        message: "currency must be an ISO 4217 code such as USD, EUR or PKR"
      }, status: :unprocessable_entity
    end

    @family.update!(currency: currency)
    render :show
  end

  private

    def ensure_read_scope
      authorize_scope!(:read)
    end

    def ensure_write_scope
      authorize_scope!(:write)
    end

    def ensure_admin
      return if current_resource_owner.admin?

      render json: { error: "forbidden", message: "Only a family admin can change family settings" }, status: :forbidden
    end
end
