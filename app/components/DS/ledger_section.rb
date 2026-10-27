class DS::LedgerSection < DesignSystemComponent
  # A titled block on the page background: a display-font heading over a 1px
  # ink rule, an optional link or control on the right, then the content. The
  # ledger's replacement for a shadowed card around a list or chart.
  #
  #   <%= render DS::LedgerSection.new(title: t(".where_it_went"), link_text: t(".budget"), href: budgets_path) do %>
  #     ...rows...
  #   <% end %>
  #
  # Pass `divided: true` to rule a hairline under every direct child (ledger
  # rows). Use the `action` slot instead of link_text/href for anything that
  # isn't a plain link, such as a legend or a DS::MonthSwitcher.
  renders_one :action

  attr_reader :title, :href, :link_text, :heading_level, :divided, :opts

  def initialize(title:, href: nil, link_text: nil, heading_level: 2, divided: false, **opts)
    @title = title
    @href = href
    @link_text = link_text
    @heading_level = heading_level
    @divided = divided
    @opts = opts
  end

  def heading_id
    @heading_id ||= opts[:id] ? "#{opts[:id]}-heading" : "ledger-section-#{object_id}"
  end

  def heading_tag
    "h#{heading_level.to_i.clamp(2, 6)}"
  end

  def container_classes
    class_names("flex flex-col", opts[:class])
  end

  def body_classes
    class_names("[&>*]:border-b [&>*]:border-divider" => divided)
  end

  def link?
    href.present? && link_text.present?
  end
end
