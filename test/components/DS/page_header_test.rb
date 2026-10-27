require "test_helper"

class DS::PageHeaderTest < ViewComponent::TestCase
  test "renders the eyebrow over a display-font h1" do
    render_inline(DS::PageHeader.new(title: "October 2026", eyebrow: "Household · PKR"))

    assert_selector "header h1.font-display", text: "October 2026"
    assert_selector "header p.text-secondary", text: "Household · PKR"
  end

  test "renders actions only when given" do
    render_inline(DS::PageHeader.new(title: "Activity"))
    assert_no_selector "header > div + div"

    render_inline(DS::PageHeader.new(title: "Activity")) { |header| header.with_actions { "<button>Go</button>".html_safe } }
    assert_selector "header button", text: "Go"
  end
end
