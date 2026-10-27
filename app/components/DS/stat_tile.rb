class DS::StatTile < DesignSystemComponent
  # One headline figure: a small label, a big display-font number and an
  # optional sub-line. Sits in a DS::StatGrid (which draws the ink rule above
  # the row) or on its own.
  #
  #   <%= render DS::StatTile.new(label: t(".came_in"), value: format_money(income), sub: t(".salary"), tone: :in) %>
  #
  # Tones colour the value (and `sub_tone` the sub-line):
  #   :default — ink. Spending is plain ink, never red.
  #   :in      — cobalt (text-success), money coming in.
  #   :out     — amber (text-warning), money owed or over budget.
  #   :muted   — secondary grey; the sub-line's default.
  TONES = {
    default: "text-primary",
    in: "text-success",
    out: "text-warning",
    muted: "text-secondary"
  }.freeze

  attr_reader :label, :value, :sub, :tone, :sub_tone, :opts

  def initialize(label:, value:, sub: nil, tone: :default, sub_tone: :muted, **opts)
    @label = label
    @value = value
    @sub = sub
    @tone = tone.to_sym
    @sub_tone = sub_tone.to_sym
    @opts = opts
  end

  def container_classes
    class_names("flex min-w-0 flex-col gap-1.5 py-4 pr-5 border-b border-divider", opts[:class])
  end

  def value_classes
    class_names("font-display text-3xl md:text-4xl font-semibold tracking-tight tabular-nums privacy-sensitive break-words", TONES.fetch(tone))
  end

  def sub_classes
    class_names("text-sm", TONES.fetch(sub_tone))
  end
end
