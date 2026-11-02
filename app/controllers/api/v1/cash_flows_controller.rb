class Api::V1::CashFlowsController < Api::V1::BaseController
  PERIOD_KEYS = %w[last_3_months last_6_months last_12_months all_time].freeze

  before_action -> { authorize_scope!(:read) }

  def show
    response.headers["Cache-Control"] = "private, no-store"
    today = Date.current
    statement = IncomeStatement.new(current_resource_owner.family, user: current_resource_owner)
    if params[:include] && params[:view]
      return invalid_query("invalid_view", "include and view cannot be combined")
    end
    unless [ nil, "sankey" ].include?(params[:include]) && [ nil, "sankey" ].include?(params[:view])
      return invalid_query("invalid_view", "include and view support only sankey")
    end
    if params[:group_by] && params[:view] != "sankey"
      return invalid_query("invalid_group_by", "group_by requires view=sankey")
    end
    group_by = params[:group_by] || "category"
    unless IncomeStatement::CashFlowGraph::GROUPINGS.key?(group_by)
      return invalid_query("invalid_group_by", "group_by must be category or account")
    end
    if [ params[:month], params[:period], params[:start_date] || params[:end_date] ].compact.size > 1
      return invalid_query("invalid_period", "Use only one of month, period, or start_date and end_date")
    end

    month = nil
    compare = true
    if params[:start_date] || params[:end_date]
      start_date, end_date = parse_date(params[:start_date]), parse_date(params[:end_date])
      graph = params[:view] == "sankey"
      unless start_date && end_date && start_date <= end_date && (graph || start_date <= today)
        return invalid_query("invalid_period", "start_date and end_date must be ISO dates in order, starting no later than today")
      end
      # A graph keeps its explicit bounds; a statement can't close in the future.
      period = Period.custom(start_date: start_date, end_date: graph ? end_date : [ end_date, today ].min)
    elsif params[:period]
      return invalid_query("invalid_period", "period must be one of #{PERIOD_KEYS.join(', ')}") unless PERIOD_KEYS.include?(params[:period])

      if params[:period] == "all_time"
        # From the oldest entry of any kind, opening balances included, so an
        # all-time statement opens at zero.
        period = Period.custom(start_date: [ current_resource_owner.family.oldest_entry_date, today ].min, end_date: today)
        compare = false
      else
        period = Period.from_key(params[:period])
      end
    else
      month = params[:month].nil? ? today.beginning_of_month : parse_date(params[:month])
      unless month && month.day == 1 && month <= today
        return invalid_query("invalid_month", "month must be a non-future ISO first day (YYYY-MM-01)")
      end
      period = Period.custom(start_date: month, end_date: [ month.end_of_month, today ].min)
    end

    if params[:view] == "sankey"
      # Arbitrary graph ranges must not allocate a daily comparison series.
      render json: IncomeStatement::CashFlowGraph.new(statement, period: period, group_by: group_by, as_of: today)
    elsif month
      render json: IncomeStatement::CashFlow.new(statement, month: month, as_of: today, include_sankey: params[:include] == "sankey")
    else
      render json: IncomeStatement::CashFlow.new(statement, period: period, compare: compare, as_of: today, include_sankey: params[:include] == "sankey")
    end
  end

  private
    def invalid_query(error, message)
      render json: { error: error, message: message }, status: :unprocessable_entity
    end
end
