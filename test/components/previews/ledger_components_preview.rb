# The household ledger primitives, shown the way a page uses them.
class LedgerComponentsPreview < ViewComponent::Preview
  LABELS = [ [ "Groceries", "#121413", "Rs 52,900" ], [ "Home & bills", "#2445C8", "Rs 43,800" ], [ "School fees", "#9A4F06", "Rs 34,650" ] ].freeze

  # @display container_classes max-w-[1100px]
  def page_header
    render DS::PageHeader.new(title: "October 2026", eyebrow: "Household · PKR") do |header|
      header.with_actions { render DS::MonthSwitcher.new(month: Date.new(2026, 10, 1), href_for: ->(_month) { "#" }, max: Date.new(2026, 10, 1)) }
    end
  end

  # @display container_classes max-w-[1100px]
  def stat_grid
    render DS::StatGrid.new do |grid|
      grid.with_tile(label: "Spent", value: "Rs 182,400", sub: "Rs 7,500 more than Sep")
      grid.with_tile(label: "Came in", value: "Rs 250,000", sub: "Salary, 25 Oct", tone: :in)
      grid.with_tile(label: "Left over", value: "Rs 67,600", sub: "27% of income kept")
      grid.with_tile(label: "What we owe", value: "Rs 400,000", tone: :out)
    end
  end

  # @display container_classes max-w-[560px]
  def ledger_section
    render DS::LedgerSection.new(title: "Where it went", link_text: "Budget", href: "#", divided: true) do
      safe_join(LABELS.map do |name, color, amount|
        content_tag(:div, class: "flex items-center justify-between min-h-11") do
          safe_join([ render(DS::LabelDot.new(color: color, label: name)), content_tag(:span, amount, class: "font-mono tabular-nums") ])
        end
      end)
    end
  end

  # @param month date
  def month_switcher(month: "2026-10-01")
    render DS::MonthSwitcher.new(month: Date.parse(month.to_s), href_for: ->(_month) { "#" })
  end

  def label_dot
    render DS::LabelDot.new(color: "#2445C8", label: "Home & bills")
  end
end
