class DS::StatGrid < DesignSystemComponent
  # A row of DS::StatTile figures under a 2px ink rule. Tiles flow into as
  # many columns as fit (min 200px each), so four tiles sit 4×1, 2×2 or 1×4
  # without breakpoints.
  #
  #   <%= render DS::StatGrid.new do |grid| %>
  #     <% grid.with_tile(label: t(".spent"), value: format_money(spent)) %>
  #     <% grid.with_tile(label: t(".came_in"), value: format_money(income), tone: :in) %>
  #   <% end %>
  renders_many :tiles, DS::StatTile

  attr_reader :opts

  def initialize(**opts)
    @opts = opts
  end

  def container_classes
    class_names("grid grid-cols-[repeat(auto-fit,minmax(min(200px,100%),1fr))] border-t-2 border-solid", opts[:class])
  end

  erb_template <<~ERB
    <%= tag.section class: container_classes, **opts.except(:class) do %>
      <% tiles.each do |tile| %><%= tile %><% end %>
    <% end %>
  ERB
end
