class DS::PageHeader < DesignSystemComponent
  # The top of a primary page: an optional small eyebrow over a large
  # display-font title, with page controls (a DS::MonthSwitcher, buttons) on
  # the right. Wraps onto two lines on phones.
  #
  #   <%= render DS::PageHeader.new(title: "October 2026", eyebrow: "Household · PKR") do |header| %>
  #     <% header.with_actions do %>
  #       <%= render DS::MonthSwitcher.new(month: @month) %>
  #     <% end %>
  #   <% end %>
  renders_one :actions

  attr_reader :title, :eyebrow, :opts

  def initialize(title:, eyebrow: nil, **opts)
    @title = title
    @eyebrow = eyebrow
    @opts = opts
  end

  def container_classes
    class_names("flex flex-wrap items-end justify-between gap-4", opts[:class])
  end
end
