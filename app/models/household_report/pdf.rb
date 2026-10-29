require "prawn"

# Draws a HouseholdReport in the app's "Broadsheet ledger" style: paper
# background, ink text, cobalt for money in, amber for money out, hairline
# rules and no shadows. Page one is the summary; the entries follow, grouped
# by month with a subtotal per month.
class HouseholdReport::Pdf
  PAPER = "F3F4EF"
  INK = "121413"
  MUTED = "4A4F4B"
  HAIRLINE = "D9DBD4"
  MONEY_IN = "2445C8"
  MONEY_OUT = "9A4F06"

  FONT_DIR = Rails.root.join("vendor/fonts/hisaab")
  MARGIN = [ 44, 40, 52, 40 ].freeze # top, right, bottom, left
  ROW_HEIGHT = 15
  # Date, description, label, account, in, out (sums to the A4 content width).
  ENTRY_COLUMNS = [ 48, 160, 92, 85, 65, 65 ].freeze
  # Subtotal "Net" line: the in and out columns merged.
  NET_COLUMNS = ENTRY_COLUMNS.first(4) + [ ENTRY_COLUMNS.last(2).sum ]
  LABEL_COLUMNS = [ 265, 95, 95, 60 ].freeze

  def initialize(report)
    @report = report
  end

  def render
    @pdf = Prawn::Document.new(
      page_size: "A4",
      margin: MARGIN,
      info: { Title: "Hisaab report", Creator: "Hisaab" }
    )
    register_fonts
    paint_paper

    summary
    entries if report.rows.any?
    footer

    pdf.render
  end

  private
    attr_reader :report, :pdf

    def register_fonts
      pdf.font_families.update(
        "Plex" => { normal: font_path("IBMPlexSans-Regular.ttf"), bold: font_path("IBMPlexSans-SemiBold.ttf") },
        "PlexMono" => { normal: font_path("IBMPlexMono-Regular.ttf"), bold: font_path("IBMPlexMono-Medium.ttf") },
        "Bricolage" => { normal: font_path("BricolageGrotesque.ttf") }
      )
      pdf.font "Plex"
    end

    def font_path(name)
      FONT_DIR.join(name).to_s
    end

    def paint_paper
      pdf.canvas do
        pdf.fill_color PAPER
        pdf.fill_rectangle [ 0, pdf.bounds.top ], pdf.bounds.width, pdf.bounds.height
      end
      pdf.fill_color INK
    end

    def new_page
      pdf.start_new_page
      paint_paper
    end

    def ensure_space(height)
      new_page if pdf.cursor < height
    end

    # --- Summary -----------------------------------------------------------

    def summary
      masthead
      period_details
      totals_block
      label_table
    end

    def masthead
      top = pdf.cursor
      draw_mark(pdf.bounds.left, top, 34)
      pdf.font("Bricolage") do
        pdf.text_box "Hisaab report", at: [ 46, top + 4 ], size: 26, color: INK, width: 330, height: 40, single_line: true
      end
      pdf.text_box report.family.name.to_s, at: [ 47, top - 26 ], size: 11, color: MUTED,
        width: 330, height: 14, single_line: true, overflow: :ellipses
      pdf.text_box "Generated #{I18n.l(Date.current, format: '%-d %b %Y')}", at: [ pdf.bounds.right - 160, top - 4 ],
        width: 160, size: 8, color: MUTED, align: :right
      pdf.move_down 46
      rule(INK, 1)
      pdf.move_down 14
    end

    # The H mark from design/brand/hisaab-mark-transparent.svg (512px grid).
    def draw_mark(x, top, size)
      scale = size / 512.0
      rect = ->(x1, y1, x2, y2) { pdf.fill_rectangle [ x + x1 * scale, top - y1 * scale ], (x2 - x1) * scale, (y2 - y1) * scale }
      pdf.fill_color INK
      rect.call(302.03, 88.32, 353.6, 323.84)
      rect.call(158.4, 88.32, 209.97, 323.84)
      rect.call(195.39, 183.48, 328.56, 227.07)
      pdf.fill_color MONEY_IN
      rect.call(134.98, 352.0, 377.02, 374.53)
      rect.call(134.98, 390.91, 377.02, 413.44)
      pdf.fill_color INK
    end

    def period_details
      detail("Period", "#{long_date(report.start_date)} – #{long_date(report.end_date)}")
      detail("Labels", labels_description)
      detail("Accounts", accounts_description)
      pdf.move_down 10
    end

    def detail(label, value)
      top = pdf.cursor
      caps(label, at: [ 0, top - 1 ], width: 80)
      height = pdf.height_of(value, width: pdf.bounds.width - 80, size: 10)
      pdf.text_box value, at: [ 80, top ], width: pdf.bounds.width - 80, height: height + 2, size: 10, color: INK
      pdf.move_down height + 6
    end

    def labels_description
      return "All labels" if report.all_labels?

      return "All labels, without unlabelled entries" if report.categories.nil?

      names = report.categories.map(&:name).sort_by(&:downcase)
      names << "Unlabelled" if report.include_uncategorized
      names.any? ? names.join(", ") : "None"
    end

    def accounts_description
      report.all_accounts? ? "All accounts" : report.accounts.map(&:name).sort_by(&:downcase).join(", ")
    end

    def totals_block
      rule(HAIRLINE)
      pdf.move_down 12
      totals = report.totals
      width = pdf.bounds.width / 3.0
      top = pdf.cursor
      [ "Money in", "Money out", "Net" ].each_with_index { |label, i| caps(label, at: [ i * width, top ], width: width) }
      line_top = top - 14
      if totals.empty?
        3.times { |i| figure(money(0, report.family.currency), [ i * width, line_top ], width, INK) }
        line_top -= 24
      end
      totals.each do |total|
        figure(money(total.money_in, total.currency), [ 0, line_top ], width, MONEY_IN)
        figure(money(total.money_out, total.currency), [ width, line_top ], width, MONEY_OUT)
        figure(money(total.net, total.currency, signed: true), [ 2 * width, line_top ], width, INK)
        line_top -= 24
      end
      pdf.move_cursor_to line_top - 4
      count = report.rows.size
      pdf.text "#{count} #{count == 1 ? 'entry' : 'entries'}", size: 8.5, color: MUTED
      pdf.move_down 18
    end

    def figure(text, at, width, color)
      pdf.font("PlexMono", style: :bold) do
        pdf.text_box text, at: at, width: width - 8, height: 22, size: 17, color: color, overflow: :shrink_to_fit, single_line: true
      end
    end

    def label_table
      section_title("By label")
      if report.rows.empty?
        pdf.text "No entries in this period.", size: 10, color: MUTED
        return
      end

      table_header(LABEL_COLUMNS, [ [ "Label", :left ], [ "In", :right ], [ "Out", :right ], [ "Entries", :right ] ])
      show_currency = report.currencies.size > 1
      report.label_totals.each do |total|
        ensure_space(ROW_HEIGHT + 4)
        name = total.category&.name || "Unlabelled"
        name = "#{name} (#{total.currency})" if show_currency
        top = pdf.cursor
        swatch(total.category&.color, 0, top - 4.5)
        cells(LABEL_COLUMNS, top, [
          [ name, :left, INK, :sans, 12 ],
          [ amount_or_dash(total.money_in, total.currency), :right, MONEY_IN, :mono ],
          [ amount_or_dash(total.money_out, total.currency), :right, MONEY_OUT, :mono ],
          [ total.count.to_s, :right, INK, :mono ]
        ])
        row_rule
      end
    end

    def swatch(color, x, top)
      hex = color.to_s.delete_prefix("#")
      if hex.match?(/\A\h{6}\z/)
        pdf.fill_color hex
        pdf.fill_rectangle [ x, top ], 6, 6
        pdf.fill_color INK
      else
        pdf.stroke_color MUTED
        pdf.line_width 0.5
        pdf.stroke_rectangle [ x + 0.25, top - 0.25 ], 5.5, 5.5
      end
    end

    # --- Entries -----------------------------------------------------------

    def entries
      new_page
      section_title("Entries")
      report.rows_by_month.each do |month, rows|
        month_header(month)
        rows.each do |row|
          if pdf.cursor < ROW_HEIGHT + 4
            new_page
            month_header(month, continued: true)
          end
          entry_row(row)
        end
        month_subtotal(month, rows)
      end
    end

    def month_header(month, continued: false)
      ensure_space(60)
      pdf.move_down 6 unless continued
      title = month.strftime("%B %Y")
      title += " (continued)" if continued
      pdf.font("Bricolage") { pdf.text title, size: 13, color: INK }
      pdf.move_down 4
      table_header(ENTRY_COLUMNS, [
        [ "Date", :left ], [ "Description", :left ], [ "Label", :left ], [ "Account", :left ], [ "In", :right ], [ "Out", :right ]
      ])
    end

    def entry_row(row)
      amount = money(row.amount, row.currency)
      cells(ENTRY_COLUMNS, pdf.cursor, [
        [ row.date.strftime("%-d %b"), :left, MUTED, :mono ],
        [ row.name.to_s, :left, INK, :sans ],
        [ row.category&.name || "Unlabelled", :left, row.category ? INK : MUTED, :sans ],
        [ row.account_name.to_s, :left, MUTED, :sans ],
        [ row.direction == :in ? amount : "", :right, MONEY_IN, :mono ],
        [ row.direction == :out ? amount : "", :right, MONEY_OUT, :mono ]
      ])
      row_rule
    end

    def month_subtotal(month, rows)
      totals = report.totals(rows)
      if pdf.cursor < ROW_HEIGHT * totals.size * 2 + 4
        new_page
        month_header(month, continued: true)
      end
      rule(INK, 0.75)
      totals.each_with_index do |total, i|
        label = i.zero? ? "#{month.strftime('%B')} subtotal" : ""
        label = [ label, total.currency ].reject(&:blank?).join(" · ") if totals.size > 1
        cells(ENTRY_COLUMNS, pdf.cursor, [
          [ "", :left, INK, :sans ],
          [ label, :left, INK, :sans_bold ],
          [ "#{total.count} #{total.count == 1 ? 'entry' : 'entries'}", :left, MUTED, :sans ],
          [ "", :left, INK, :sans ],
          [ money(total.money_in, total.currency), :right, MONEY_IN, :mono_bold ],
          [ money(total.money_out, total.currency), :right, MONEY_OUT, :mono_bold ]
        ])
        cells(NET_COLUMNS, pdf.cursor, [
          [ "", :left, INK, :sans ], [ "", :left, INK, :sans ], [ "", :left, INK, :sans ],
          [ "Net", :right, MUTED, :sans ],
          [ money(total.net, total.currency, signed: true), :right, INK, :mono_bold ]
        ])
      end
      pdf.move_down 14
    end

    # --- Shared drawing ----------------------------------------------------

    def section_title(title)
      ensure_space(80)
      pdf.font("Bricolage") { pdf.text title, size: 16, color: INK }
      pdf.move_down 3
      rule(INK, 1)
      pdf.move_down 6
    end

    def table_header(widths, headings)
      top = pdf.cursor
      x = 0
      headings.zip(widths).each do |(label, align), width|
        caps(label, at: [ x + 3, top - 2 ], width: width - 6, align: align)
        x += width
      end
      pdf.move_down 14
      rule(INK, 0.5)
    end

    # cells: [text, align, color, font, left_inset?] per column; draws one row
    # and moves the cursor below it. Text that does not fit ends in "...".
    def cells(widths, top, values)
      x = 0
      values.zip(widths).each do |(text, align, color, face, inset), width|
        inset ||= 3
        family, style, size = { sans: [ "Plex", :normal, 8.5 ], sans_bold: [ "Plex", :bold, 8.5 ],
                                mono: [ "PlexMono", :normal, 8 ], mono_bold: [ "PlexMono", :bold, 8 ] }.fetch(face)
        pdf.font(family, style: style) do
          pdf.text_box text, at: [ x + inset, top - 3.5 ], width: width - inset - 3, height: ROW_HEIGHT - 3,
            size: size, color: color, align: align, single_line: true, overflow: :ellipses
        end
        x += width
      end
      pdf.move_cursor_to top - ROW_HEIGHT
    end

    def row_rule
      rule(HAIRLINE, 0.5)
    end

    def rule(color, width = 0.5)
      pdf.stroke_color color
      pdf.line_width width
      pdf.stroke_horizontal_line 0, pdf.bounds.width, at: pdf.cursor
    end

    def caps(text, at:, width:, align: :left)
      pdf.font("Plex", style: :bold) do
        pdf.text_box text.upcase, at: at, width: width, size: 6.5, color: MUTED, character_spacing: 0.6,
          align: align, single_line: true
      end
    end

    def footer
      name = report.family.name.to_s
      pdf.repeat(:all) do
        pdf.text_box "Hisaab · #{name}", at: [ 0, -18 ], width: 300, height: 10, size: 7, color: MUTED, single_line: true, overflow: :ellipses
      end
      pdf.number_pages "Page <page> of <total>", at: [ pdf.bounds.right - 150, -18 ], width: 150, align: :right, size: 7, color: MUTED
    end

    # --- Formatting ----------------------------------------------------------

    def long_date(date)
      date.strftime("%-d %b %Y")
    end

    def amount_or_dash(amount, currency)
      amount.zero? ? "–" : money(amount, currency)
    end

    # Matches the app: "Rs 2,500" for PKR, decimals only when not whole;
    # other currencies use Money's own symbol and separators.
    def money(amount, currency, signed: false)
      value = Money.new(amount.abs, currency)
      precision = value.amount.frac.zero? ? 0 : value.currency.default_precision
      options = { precision: precision }
      options[:unit] = "Rs " if value.currency.iso_code == "PKR"
      text = value.format(options)
      return text unless amount.negative? || (signed && amount.positive?)

      "#{amount.negative? ? '−' : '+'} #{text}"
    end
end
