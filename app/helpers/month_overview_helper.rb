module MonthOverviewHelper
  # What the dashboard header covers: "October", "Last 3 months", or the dates
  # of a custom range.
  def month_overview_label(overview, month_format: "%B")
    return l(overview.month, format: month_format) unless overview.ranged?
    return overview.period.label_range unless overview.range.key

    t("pages.dashboard.ranges.#{overview.range.key}")
  end

  # [label, href, selected, frame] rows for the header's range menu. "This month"
  # returns to the month view; the custom row opens the date dialog.
  def month_overview_range_items(overview)
    selected_key = overview.ranged? ? (overview.range.key || "custom") : "month"

    [
      [ t("pages.dashboard.ranges.month"), root_path, selected_key == "month" ],
      *MonthOverview::RANGE_KEYS.map { |key| [ t("pages.dashboard.ranges.#{key}"), root_path(range: key), selected_key == key ] },
      [ t("pages.dashboard.ranges.custom"), dashboard_range_path, selected_key == "custom", :modal ]
    ]
  end
end
