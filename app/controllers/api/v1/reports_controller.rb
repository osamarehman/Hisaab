# frozen_string_literal: true

# PDF household report.
#
# @example Last month, two labels plus unlabelled rows, one account
#   GET /api/v1/reports/export.pdf?start_date=2026-09-01&end_date=2026-09-30
#     &category_ids[]=<uuid>&category_ids[]=<uuid>&include_uncategorized=true
#     &account_ids[]=<uuid>
class Api::V1::ReportsController < Api::V1::BaseController
  class InvalidSelection < StandardError
    attr_reader :error

    def initialize(error, message)
      @error = error
      super(message)
    end
  end

  before_action :ensure_read_scope

  def export
    report = HouseholdReport.new(
      family: current_resource_owner.family,
      user: current_resource_owner,
      start_date: parse_date(params[:start_date]),
      end_date: parse_date(params[:end_date]),
      categories: selected(:category_ids, current_resource_owner.family.categories),
      accounts: selected(:account_ids, accessible_accounts),
      include_uncategorized: include_uncategorized_param
    )
    return render_invalid("invalid_period", report.errors.full_messages.to_sentence) unless report.valid?

    response.headers["Cache-Control"] = "private, no-store"
    send_data report.to_pdf,
      type: "application/pdf",
      disposition: "attachment",
      filename: "hisaab-report-#{report.start_date.iso8601}-to-#{report.end_date.iso8601}.pdf"
  rescue InvalidSelection => e
    render_invalid(e.error, e.message)
  end

  private
    def accessible_accounts
      current_resource_owner.family.accounts
        .accessible_by(current_resource_owner)
        .where.not(status: "pending_deletion")
    end

    # nil when the param is absent (meaning "all"); otherwise the records,
    # every id of which must belong to the given scope.
    def selected(key, scope)
      return nil unless params.key?(key)

      ids = Array(params[key]).map(&:to_s).compact_blank.uniq
      name = key.to_s.delete_suffix("_ids")
      if ids.any? { |id| !valid_uuid?(id) } || (records = scope.where(id: ids).to_a).size != ids.size
        raise InvalidSelection.new("invalid_#{name}", "One or more #{name.pluralize} were not found")
      end

      records
    end

    def include_uncategorized_param
      return nil unless params.key?(:include_uncategorized)

      ActiveModel::Type::Boolean.new.cast(params[:include_uncategorized]) || false
    end

    def render_invalid(error, message)
      render_json({ error: error, message: message }, status: :unprocessable_entity)
    end
end
