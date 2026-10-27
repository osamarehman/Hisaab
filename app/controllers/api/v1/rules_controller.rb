# frozen_string_literal: true

class Api::V1::RulesController < Api::V1::BaseController
  include Pagy::Backend

  BOOLEAN_FILTERS = {
    "true" => true,
    "1" => true,
    "false" => false,
    "0" => false
  }.freeze
  RESOURCE_TYPES = %w[transaction].freeze

  before_action :ensure_read_scope, only: %i[index show]
  before_action :ensure_write_scope, only: %i[create destroy]
  before_action :reject_guest_writes!, only: %i[create destroy]
  before_action :set_rule, only: %i[show destroy]

  def index
    return render_invalid_resource_type_filter if invalid_resource_type_filter?

    @per_page = safe_per_page_param
    rules_query = current_resource_owner.family.rules
      .includes(:actions, conditions: :sub_conditions)
      .order(:created_at, :id)

    rules_query = rules_query.where(resource_type: params[:resource_type]) if params[:resource_type].present?
    if params[:active].present?
      active = parse_boolean_filter(params[:active])
      return if performed?

      rules_query = rules_query.where(active: active)
    end

    @pagy, @rules = pagy(
      rules_query,
      page: safe_page_param,
      limit: @per_page
    )

    render :index
  end

  def show
    render :show
  end

  # Creates an auto-label keyword rule: transaction name contains `keyword`
  # -> set category `category_id`.
  def create
    attrs = keyword_rule_params
    keyword = attrs[:keyword].to_s.strip
    return render_validation_error("keyword is required") if keyword.blank?

    category = current_resource_owner.family.categories.find_by(id: attrs[:category_id]) if valid_uuid?(attrs[:category_id].to_s)
    return render_validation_error("category_id must be a category in your family") unless category

    @rule = Rule.create_keyword_category_rule!(
      current_resource_owner.family,
      keyword: keyword,
      category: category,
      apply_to_existing: ActiveModel::Type::Boolean.new.cast(attrs[:apply_to_existing]) == true
    )

    render :show, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render_validation_error(e.record.errors.full_messages.to_sentence)
  end

  def destroy
    @rule.destroy!
    head :no_content
  end

  private

    def keyword_rule_params
      params.require(:rule).permit(:keyword, :category_id, :apply_to_existing)
    end

    def ensure_write_scope
      authorize_scope!(:write)
    end

    def set_rule
      @rule = current_resource_owner.family.rules
        .includes(:actions, conditions: :sub_conditions)
        .find(params[:id])
    end

    def ensure_read_scope
      authorize_scope!(:read)
    end

    def parse_boolean_filter(value)
      normalized = value.to_s.downcase
      return BOOLEAN_FILTERS[normalized] if BOOLEAN_FILTERS.key?(normalized)

      render_validation_error("active must be one of: true, false, 1, 0")
      nil
    end

    def invalid_resource_type_filter?
      params[:resource_type].present? && !params[:resource_type].in?(RESOURCE_TYPES)
    end

    def render_invalid_resource_type_filter
      render_validation_error("resource_type must be one of: #{RESOURCE_TYPES.join(", ")}")
    end
end
