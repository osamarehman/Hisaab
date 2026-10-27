require "test_helper"

class DS::LedgerBarTest < ViewComponent::TestCase
  test "fills the track to the percentage in the label colour" do
    render_inline(DS::LedgerBar.new(percent: 64, color: "#2445C8"))

    assert_selector "span[aria-hidden=true].bg-surface-inset > span[style='width: 64.0%; background-color: #2445C8']"
  end

  test "clamps the fill to the track" do
    render_inline(DS::LedgerBar.new(percent: 140, tone: :out))

    assert_selector "span.bg-warning[style='width: 100.0%']"
  end

  test "falls back to grey for anything that is not a hex colour" do
    render_inline(DS::LedgerBar.new(percent: 10, color: "red; background-image: url(x)"))

    assert_selector "span[style='width: 10.0%; background-color: var(--color-gray-400)']"
  end

  test "draws a marker only when given one" do
    render_inline(DS::LedgerBar.new(percent: 50, marker: 87))
    assert_selector "span.bg-link[style='left: 87.0%']"

    render_inline(DS::LedgerBar.new(percent: 50))
    assert_no_selector "span.bg-link"
  end
end
