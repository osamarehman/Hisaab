class DS::MonthSwitcher < DesignSystemComponent
  # ‹ Oct 2026 › — steps a page through months with plain links, so the month
  # lives in the URL. By default each arrow links to the current path with
  # `?<param>=YYYY-MM` (other query params kept); pass `href_for:` to build the
  # URL yourself, e.g. `href_for: ->(month) { budget_path(Budget.date_to_param(month)) }`.
  #
  #   <%= render DS::MonthSwitcher.new(month: @month, max: Date.current) %>
  #
  # An arrow past `min:` / `max:` renders disabled instead of as a link.
  attr_reader :month, :param, :min, :max, :href_for, :label_format

  def initialize(month:, param: :month, href_for: nil, min: nil, max: nil, label_format: "%b %Y")
    @month = month.to_date.beginning_of_month
    @param = param.to_s
    @href_for = href_for
    @min = min&.to_date&.beginning_of_month
    @max = max&.to_date&.beginning_of_month
    @label_format = label_format
  end

  def previous_month
    month.prev_month
  end

  def next_month
    month.next_month
  end

  def previous_enabled?
    min.nil? || previous_month >= min
  end

  def next_enabled?
    max.nil? || next_month <= max
  end

  def label
    I18n.l(month, format: label_format)
  end

  def href(target)
    return href_for.call(target) if href_for

    query = request.query_parameters.merge(param => target.strftime("%Y-%m"))
    "#{request.path}?#{query.to_query}"
  end

  def arrows
    [
      { month: previous_month, enabled: previous_enabled?, icon: "chevron-left", rel: "prev", label: t("ds.month_switcher.previous") },
      { month: next_month, enabled: next_enabled?, icon: "chevron-right", rel: "next", label: t("ds.month_switcher.next") }
    ]
  end

  def arrow_tag(arrow)
    glyph = helpers.icon(arrow[:icon], color: "current")
    classes = "inline-flex items-center justify-center w-11 h-10 text-primary"

    if arrow[:enabled]
      link_to glyph, href(arrow[:month]), class: class_names(classes, "hover:bg-surface-inset-hover focus-ring"), rel: arrow[:rel], aria: { label: arrow[:label] }
    else
      tag.span glyph, class: class_names(classes, "opacity-40"), role: "link", aria: { disabled: true, label: arrow[:label] }
    end
  end
end
