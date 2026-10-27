class DS::LedgerBar < DesignSystemComponent
  # A flat horizontal bar on a hairline track: a label's share of spending, or
  # how much of a budget limit is used. Square ends, no animation.
  #
  #   <%= render DS::LedgerBar.new(percent: 64, color: category.color) %>
  #   <%= render DS::LedgerBar.new(percent: 100, tone: :out, size: :md) %>
  #
  # `color:` is a label's hex colour (user data, set inline; anything else
  # falls back to grey). Without it the fill takes `tone:` — :default ink,
  # :in cobalt, :out amber. `marker:` draws a thin cobalt tick at that
  # percentage, such as how far through the month today is.
  TONES = {
    default: "bg-inverse",
    in: "bg-success",
    out: "bg-warning"
  }.freeze

  SIZES = { sm: "h-1.5", md: "h-2", lg: "h-4" }.freeze

  attr_reader :percent, :color, :tone, :size, :marker, :opts

  def initialize(percent:, color: nil, tone: :default, size: :md, marker: nil, **opts)
    @percent = percent.to_f.clamp(0.0, 100.0)
    @color = color
    @tone = tone.to_sym
    @size = size.to_sym
    @marker = marker&.to_f&.clamp(0.0, 100.0)
    @opts = opts
  end

  def call
    tag.span(class: class_names("relative block bg-surface-inset", SIZES.fetch(size), opts[:class]), aria: { hidden: true }, **opts.except(:class)) do
      safe_join([ fill_tag, marker_tag ].compact)
    end
  end

  private
    def fill_tag
      if color
        tag.span(class: "block h-full", style: "width: #{percent.round(1)}%; background-color: #{hex_color}")
      else
        tag.span(class: class_names("block h-full", TONES.fetch(tone)), style: "width: #{percent.round(1)}%")
      end
    end

    def marker_tag
      return unless marker

      tag.span(class: "absolute -inset-y-1 w-0.5 bg-link", style: "left: #{marker.round(1)}%")
    end

    def hex_color
      color.to_s.match?(DS::LabelDot::HEX) ? color : "var(--color-gray-400)"
    end
end
