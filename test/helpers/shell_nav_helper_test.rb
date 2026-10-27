require "test_helper"

# ApplicationHelper#primary_nav_items and friends: the household shell's nav.
class ShellNavHelperTest < ActionView::TestCase
  include ApplicationHelper

  setup do
    @user = users(:family_admin)
    Current.session = @user.sessions.create!
  end

  teardown { Current.session = nil }

  test "lists the household destinations in sidebar order" do
    keys = primary_nav_items.map { |item| item[:key] }

    assert_equal %i[home activity statements budget accounts labels assistant], keys
    assert_equal "Labels", primary_nav_items.find { |item| item[:key] == :labels }[:name]
  end

  test "drops Assistant when the family has no chat surface" do
    Current.family.stubs(:assistant_enabled?).returns(false)

    assert_not_includes primary_nav_items.map { |item| item[:key] }, :assistant
    assert_equal %i[home activity statements accounts], mobile_tab_nav_items.map { |item| item[:key] }
  end

  test "the phone's bottom bar is Home, Activity, Assistant, Accounts" do
    assert_equal %i[home activity assistant accounts], mobile_tab_nav_items.map { |item| item[:key] }
  end

  test "intro users only see the intro destinations" do
    @user.stubs(:ui_layout_intro?).returns(true)

    assert_equal %i[home intro], primary_nav_items.map { |item| item[:key] }
  end

  test "the Statements badge counts this month's unlabelled transactions" do
    before = statements_review_count
    account = accounts(:depository)
    account.entries.create!(
      name: "Unlabelled", date: Date.current.beginning_of_month, amount: 25, currency: account.currency,
      entryable: Transaction.new
    )
    account.entries.create!(
      name: "Last month", date: Date.current.beginning_of_month - 1.day, amount: 25, currency: account.currency,
      entryable: Transaction.new
    )

    assert_equal before + 1, statements_review_count
  end
end
