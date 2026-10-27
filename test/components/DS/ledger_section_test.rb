require "test_helper"

class DS::LedgerSectionTest < ViewComponent::TestCase
  test "heads the content with a display title over an ink rule" do
    render_inline(DS::LedgerSection.new(title: "Where it went")) { "<p>Groceries</p>".html_safe }

    assert_selector "section[aria-labelledby] > div.border-b.border-solid h2.font-display", text: "Where it went"
    assert_selector "section > div > p", text: "Groceries"
    assert_no_selector "a"
  end

  test "adds the right-hand link when both text and href are given" do
    render_inline(DS::LedgerSection.new(title: "Where it went", link_text: "Budget", href: "/budgets"))

    assert_selector "a.text-link[href='/budgets']", text: "Budget"
  end

  test "the action slot replaces the link" do
    render_inline(DS::LedgerSection.new(title: "Six months", link_text: "Ignored", href: "/x")) do |section|
      section.with_action { "<span>Legend</span>".html_safe }
    end

    assert_selector "span", text: "Legend"
    assert_no_selector "a"
  end

  test "divided rules every row and heading_level picks the tag" do
    render_inline(DS::LedgerSection.new(title: "Rows", divided: true, heading_level: 3, id: "rows")) { "<p>a</p>".html_safe }

    assert_selector "section#rows[aria-labelledby='rows-heading'] h3#rows-heading", text: "Rows"
    assert_selector "div[class*='border-divider'] > p", text: "a"
  end
end
