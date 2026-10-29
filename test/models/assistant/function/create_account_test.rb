require "test_helper"

class Assistant::Function::CreateAccountTest < ActiveSupport::TestCase
  setup do
    @user = users(:family_admin)
    @function = Assistant::Function::CreateAccount.new(@user)
  end

  test "creates a cash account owned by the user with its opening balance" do
    result = @function.call("name" => "Cash in hand", "kind" => "cash", "balance" => 5000)

    assert result[:success]
    account = @user.family.accounts.find(result[:account][:id])
    assert_equal "Depository", account.accountable_type
    assert_equal "cash", account.subtype
    assert_equal BigDecimal("5000"), account.balance
    assert_equal @user, account.owner
    assert account.valuations.any?
  end

  test "preview validates without creating" do
    assert_no_difference "Account.count" do
      preview = @function.preview("name" => "Committee", "kind" => "savings", "balance" => 10000)
      assert_equal "create_account", preview[:kind]
      assert_equal "Committee", preview[:details][:name]
    end
  end

  test "rejects an unknown kind, a duplicate name and guests" do
    assert_equal "invalid_kind", @function.call("name" => "X", "kind" => "crypto")[:error]
    existing = @user.family.accounts.visible.first
    assert_equal "already_exists", @function.preview("name" => existing.name.upcase, "kind" => "cash")[:error]

    guest = users(:family_admin)
    guest.stubs(:guest?).returns(true)
    assert_equal "forbidden", Assistant::Function::CreateAccount.new(guest).call("name" => "Y", "kind" => "cash")[:error]
  end
end
