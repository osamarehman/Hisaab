require "test_helper"

class DS::LabelDotTest < ViewComponent::TestCase
  test "renders a hidden swatch in the label colour" do
    render_inline(DS::LabelDot.new(color: "#2445C8"))

    assert_selector "span[aria-hidden=true][style='background-color: #2445C8']"
  end

  test "with a label, pairs the swatch with the name" do
    render_inline(DS::LabelDot.new(color: "#121413", label: "Groceries"))

    assert_selector "span.inline-flex > span[aria-hidden=true] + span", text: "Groceries"
  end

  test "falls back to grey for anything that is not a hex colour" do
    render_inline(DS::LabelDot.new(color: "red; background-image: url(x)"))

    assert_selector "span[style='background-color: var(--color-gray-400)']"
  end
end
