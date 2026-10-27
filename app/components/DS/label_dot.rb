class DS::LabelDot < DesignSystemComponent
  # The small colour square that marks a label (category) in lists, legends
  # and bars. Category colours are user data, so the colour is set inline;
  # anything that isn't a hex colour falls back to a neutral grey.
  #
  #   <%= render DS::LabelDot.new(color: category.color) %>
  #   <%= render DS::LabelDot.new(color: category.color, label: category.name) %>
  HEX = /\A#(?:\h{3}|\h{4}|\h{6}|\h{8})\z/

  SIZES = { sm: "size-2", md: "size-2.5", lg: "size-3" }.freeze

  attr_reader :color, :label, :size, :opts

  def initialize(color:, label: nil, size: :md, **opts)
    @color = color
    @label = label
    @size = size.to_sym
    @opts = opts
  end

  def swatch_style
    "background-color: #{color.to_s.match?(HEX) ? color : "var(--color-gray-400)"}"
  end

  def call
    swatch = tag.span(class: class_names("inline-block shrink-0", SIZES.fetch(size)), style: swatch_style, aria: { hidden: true })
    return swatch if label.blank?

    tag.span(class: class_names("inline-flex min-w-0 items-center gap-2", opts[:class]), **opts.except(:class)) do
      safe_join([ swatch, tag.span(label, class: "truncate") ])
    end
  end
end
