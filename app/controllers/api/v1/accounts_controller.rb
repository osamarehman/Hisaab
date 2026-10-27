# frozen_string_literal: true

class Api::V1::AccountsController < Api::V1::BaseController
  include Pagy::Backend

  # Manual account types the API can create. Investment, crypto, property and
  # vehicle accounts carry type-specific setup the web forms collect.
  CREATABLE_ACCOUNTABLE_TYPES = %w[Depository CreditCard Loan OtherAsset OtherLiability].freeze

  InvalidParamError = Class.new(StandardError)

  before_action :ensure_read_scope, only: [ :index, :show ]
  before_action :ensure_write_scope, only: [ :create, :update, :destroy ]
  before_action :reject_guest_writes!, only: [ :create, :update, :destroy ]
  before_action :set_manageable_account, only: [ :update, :destroy ]

  def index
    @per_page = safe_per_page_param

    @pagy, @accounts = pagy(
      accounts_scope.alphabetically,
      page: safe_page_param,
      limit: @per_page
    )

    render :index
  rescue => e
    Rails.logger.error "AccountsController#index error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "An unexpected error occurred"
    }, status: :internal_server_error
  end

  def show
    unless valid_uuid?(params[:id])
      render json: {
        error: "not_found",
        message: "Account not found"
      }, status: :not_found
      return
    end

    @account = accounts_scope.find(params[:id])

    render :show
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: "not_found",
      message: "Account not found"
    }, status: :not_found
  rescue => e
    Rails.logger.error "AccountsController#show error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "An unexpected error occurred"
    }, status: :internal_server_error
  end

  # Same path as the web's AccountableResource#create: `create_and_sync`
  # writes the opening balance valuation and the creating user owns the
  # account.
  def create
    family = current_resource_owner.family
    attributes = build_create_attributes(family)
    opening_balance_date = parse_opening_balance_date

    Account.transaction do
      @account = family.accounts.create_and_sync(
        attributes.merge(owner: current_resource_owner),
        opening_balance_date: opening_balance_date
      )
      @account.lock_saved_attributes!
    end

    render :show, status: :created
  rescue InvalidParamError => e
    render_validation_error(e.message)
  rescue ActionController::ParameterMissing
    render_validation_error("account parameters are required")
  rescue ActiveRecord::RecordInvalid => e
    render_validation_error(e.record.errors.full_messages.join(", ").presence || e.message)
  rescue => e
    Rails.logger.error "AccountsController#create error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "An unexpected error occurred"
    }, status: :internal_server_error
  end

  # Mirrors AccountableResource#update: a changed balance is written through
  # `set_current_balance` (a valuation), and the rename commits or rolls back
  # with it.
  def update
    attrs = update_params
    raise InvalidParamError, "Name can't be blank" if attrs.key?(:name) && attrs[:name].blank?

    balance = parse_decimal(attrs[:balance], "balance") if attrs.key?(:balance)
    error_message = nil

    saved = Account.transaction do
      if balance && balance != @account.balance
        result = @account.set_current_balance(balance)
        unless result.success?
          error_message = result.error
          raise ActiveRecord::Rollback
        end
      end

      if attrs.key?(:name) && !@account.update(name: attrs[:name])
        error_message = @account.errors.full_messages.join(", ")
        raise ActiveRecord::Rollback
      end

      @account.lock_saved_attributes!
      true
    end

    unless saved
      render_validation_error(error_message.presence || "Account could not be updated")
      return
    end

    @account.reload
    render :show
  rescue InvalidParamError => e
    render_validation_error(e.message)
  rescue ActionController::ParameterMissing
    render_validation_error("account parameters are required")
  rescue ActiveRecord::RecordInvalid => e
    render_validation_error(e.record.errors.full_messages.join(", ").presence || e.message)
  rescue => e
    Rails.logger.error "AccountsController#update error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "An unexpected error occurred"
    }, status: :internal_server_error
  end

  # Mirrors AccountsController#destroy: the account is marked pending deletion
  # and removed by a background job. Linked accounts must be unlinked first.
  def destroy
    if @account.linked?
      render json: {
        error: "unprocessable_entity",
        message: "Linked accounts must be unlinked before they can be deleted"
      }, status: :unprocessable_entity
      return
    end

    if @account.destroy_later == false
      render json: {
        error: "internal_server_error",
        message: "Account could not be scheduled for deletion"
      }, status: :internal_server_error
      return
    end

    head :no_content
  rescue AASM::InvalidTransition
    render json: {
      error: "not_found",
      message: "Account not found"
    }, status: :not_found
  rescue => e
    Rails.logger.error "AccountsController#destroy error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "An unexpected error occurred"
    }, status: :internal_server_error
  end

  private

    def ensure_read_scope
      authorize_scope!(:read)
    end

    def ensure_write_scope
      authorize_scope!(:write)
    end

    def accounts_scope
      scope = current_resource_owner.family.accounts
                                    .accessible_by(current_resource_owner)
                                    .includes(:accountable, account_providers: :provider)
      include_disabled_accounts? ? scope : scope.visible
    end

    def include_disabled_accounts?
      ActiveModel::Type::Boolean.new.cast(params[:include_disabled])
    end

    def set_manageable_account
      account = current_resource_owner.family.accounts
                                      .accessible_by(current_resource_owner)
                                      .where.not(status: :pending_deletion)
                                      .find_by(id: params[:id]) if valid_uuid?(params[:id])

      unless account
        render json: { error: "not_found", message: "Account not found" }, status: :not_found
        return
      end

      unless account.permission_for(current_resource_owner).in?([ :owner, :full_control ])
        render json: {
          error: "forbidden",
          message: "You do not have permission to change this account"
        }, status: :forbidden
        return
      end

      @account = account
    end

    def account_params
      params.require(:account)
    end

    def create_params
      account_params.permit(:name, :accountable_type, :subtype, :balance, :currency, :opening_balance_date)
    end

    def update_params
      account_params.permit(:name, :balance)
    end

    def build_create_attributes(family)
      attrs = create_params
      accountable_type = attrs[:accountable_type].to_s

      unless CREATABLE_ACCOUNTABLE_TYPES.include?(accountable_type)
        raise InvalidParamError, "accountable_type must be one of: #{CREATABLE_ACCOUNTABLE_TYPES.join(", ")}"
      end

      raise InvalidParamError, "Name is required" if attrs[:name].blank?

      subtype = attrs[:subtype].presence
      valid_subtypes = accountable_type.constantize::SUBTYPES.keys
      if subtype && !valid_subtypes.include?(subtype)
        raise InvalidParamError, "subtype must be one of: #{valid_subtypes.join(", ")}"
      end

      currency = attrs[:currency].presence&.upcase || family.currency
      begin
        Money::Currency.new(currency)
      rescue Money::Currency::UnknownCurrencyError
        raise InvalidParamError, "currency is not a supported currency code"
      end

      balance = attrs[:balance].present? ? parse_decimal(attrs[:balance], "balance") : 0.to_d

      {
        name: attrs[:name].strip,
        accountable_type: accountable_type,
        subtype: subtype,
        balance: balance,
        currency: currency
      }.compact
    end

    def parse_opening_balance_date
      raw = create_params[:opening_balance_date]
      return Time.zone.today - 2.years if raw.blank?

      date = parse_date(raw)
      raise InvalidParamError, "opening_balance_date must be a YYYY-MM-DD date" unless date
      raise InvalidParamError, "opening_balance_date cannot be in the future" if date > Time.zone.today

      date
    end

    def parse_decimal(value, field)
      number = BigDecimal(value.to_s.strip)
      raise ArgumentError unless number.finite?

      number
    rescue ArgumentError, TypeError
      raise InvalidParamError, "#{field} must be a number"
    end
end
