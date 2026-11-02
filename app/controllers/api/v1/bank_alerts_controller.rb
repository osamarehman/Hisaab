# Alerts parsed from forwarded bank emails, and their review: approving posts
# the pending transaction (or creates it on a chosen account); rejecting
# deletes it.
class Api::V1::BankAlertsController < Api::V1::BaseController
  before_action -> { authorize_scope!(:read) }, only: :index
  before_action -> { authorize_scope!(:read_write) }, :reject_guest_writes!, only: %i[approve reject]
  before_action :set_alert, only: %i[approve reject]

  def index
    scope = family.bank_alerts.newest_first.includes(:account)
    if params[:status].present?
      return render_validation_error("status must be one of #{BankAlert::STATUSES.join(', ')}") unless BankAlert::STATUSES.include?(params[:status])

      scope = scope.where(status: params[:status])
    end

    @per_page = safe_per_page_param
    @pagy, @alerts = pagy(scope, page: safe_page_param, limit: @per_page)
    render :index
  end

  def approve
    account = params[:account_id].present? ? accessible_accounts.find(params[:account_id]) : nil
    category = params[:category_id].present? ? family.categories.find(params[:category_id]) : nil
    @alert.approve!(account: account, category: category, name: params[:name].presence)
    render :show
  rescue BankAlert::InvalidTransition => e
    render_validation_error(e.message)
  end

  def reject
    @alert.reject!
    render :show
  rescue BankAlert::InvalidTransition => e
    render_validation_error(e.message)
  end

  private
    def family
      current_resource_owner.family
    end

    def accessible_accounts
      current_resource_owner.accessible_accounts
    end

    def set_alert
      @alert = family.bank_alerts.find(params[:id])
    end
end
