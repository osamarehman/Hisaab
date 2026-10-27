class DS::Card < DesignSystemComponent
  attr_reader :opts

  # Generic flat panel: bg-container framed by a hairline, no shadow (the
  # ledger look). Extracted from the Plan hub's budget/goals cards (#2687
  # review) — reach for this instead of repeating the class string for the
  # next card-shaped panel. For a titled block on the page background, prefer
  # DS::LedgerSection.
  def initialize(**opts)
    @opts = opts
  end

  def container_classes
    class_names("bg-container rounded-md border border-divider p-5 flex flex-col", opts[:class])
  end

  def container_opts
    opts.except(:class)
  end
end
