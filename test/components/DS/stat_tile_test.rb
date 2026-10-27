require "test_helper"

class DS::StatTileTest < ViewComponent::TestCase
  test "renders label, display value and sub-line" do
    render_inline(DS::StatTile.new(label: "Spent", value: "Rs 182,400", sub: "Rs 7,500 more than Sep"))

    assert_selector "p.text-secondary", text: "Spent"
    assert_selector "p.font-display.tabular-nums.privacy-sensitive.text-primary", text: "Rs 182,400"
    assert_selector "p.text-sm.text-secondary", text: "Rs 7,500 more than Sep"
  end

  test "tones colour money in cobalt and money owed amber" do
    render_inline(DS::StatTile.new(label: "Came in", value: "Rs 1", tone: :in, sub: "up", sub_tone: :in))
    assert_selector "p.font-display.text-success", text: "Rs 1"
    assert_selector "p.text-sm.text-success", text: "up"

    render_inline(DS::StatTile.new(label: "Owe", value: "Rs 2", tone: :out))
    assert_selector "p.font-display.text-warning", text: "Rs 2"
  end

  test "rejects an unknown tone" do
    assert_raises(KeyError) { render_inline(DS::StatTile.new(label: "x", value: "1", tone: :loud)) }
  end

  test "a grid wraps its tiles under an ink rule" do
    render_inline(DS::StatGrid.new) do |grid|
      grid.with_tile(label: "Spent", value: "1")
      grid.with_tile(label: "Came in", value: "2", tone: :in)
    end

    assert_selector "section.grid.border-t-2.border-solid > div", count: 2
  end
end
