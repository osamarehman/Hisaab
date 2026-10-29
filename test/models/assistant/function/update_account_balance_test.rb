require "test_helper"

class Assistant::Function::UpdateAccountBalanceTest < ActiveSupport::TestCase
  setup do
    @user = users(:family_admin)
    @account = accounts(:depository)
    @function = Assistant::Function::UpdateAccountBalance.new(@user)
  end

  test "sets today's balance through set_current_balance" do
    Account.any_instance.expects(:set_current_balance).with(BigDecimal("12000"))
      .returns(Account::CurrentBalanceManager::Result.new(success?: true, changes_made?: true, error: nil))

    result = @function.call("account_id" => @account.id, "balance" => 12000)

    assert result[:success]
  end

  test "preview names the account and the new balance" do
    preview = @function.preview("account_id" => @account.id, "balance" => 12000)

    assert_equal "update_balance", preview[:kind]
    assert_equal @account.name, preview[:details][:account]
    assert_equal "12000.0", preview[:details][:amount]
  end

  test "rejects an account outside the family and a bad balance" do
    assert_equal "account_not_found", @function.preview("account_id" => SecureRandom.uuid, "balance" => 1)[:error]
    assert_equal "invalid_balance", @function.preview("account_id" => @account.id, "balance" => "lots")[:error]
  end
end
