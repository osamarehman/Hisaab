require "test_helper"

class DS::MonthSwitcherTest < ViewComponent::TestCase
  test "links both arrows to the neighbouring months on the current path, keeping other params" do
    with_request_url "/transactions?q=rent&month=2026-10" do
      render_inline(DS::MonthSwitcher.new(month: Date.new(2026, 10, 14)))
    end

    assert_selector "[role=group]", text: "Oct 2026"
    assert_selector "a[rel=prev][aria-label='Previous month'][href='/transactions?month=2026-09&q=rent']"
    assert_selector "a[rel=next][aria-label='Next month'][href='/transactions?month=2026-11&q=rent']"
  end

  test "href_for builds the URLs and max disables the next arrow" do
    render_inline(DS::MonthSwitcher.new(
      month: Date.new(2026, 10, 1),
      href_for: ->(month) { "/budgets/#{month.strftime("%b-%Y").downcase}" },
      max: Date.new(2026, 10, 31)
    ))

    assert_selector "a[rel=prev][href='/budgets/sep-2026']"
    assert_no_selector "a[rel=next]"
    assert_selector "span[aria-disabled=true][aria-label='Next month']"
  end

  test "min disables the previous arrow" do
    render_inline(DS::MonthSwitcher.new(month: Date.new(2026, 1, 1), href_for: ->(_month) { "#" }, min: Date.new(2026, 1, 1)))

    assert_no_selector "a[rel=prev]"
    assert_selector "a[rel=next]"
  end
end
