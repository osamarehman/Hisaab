# frozen_string_literal: true

require "test_helper"

class Provider::FactoryTest < ActiveSupport::TestCase
  test "offers provider connections for depository accounts by default" do
    with_env_overrides("DISABLE_BANK_SYNC" => nil) do
      assert_not Provider::Factory.bank_sync_disabled?
      assert Provider::Factory.supports_account_type?("Depository")
    end
  end

  test "DISABLE_BANK_SYNC hides every provider connection" do
    with_env_overrides("DISABLE_BANK_SYNC" => "true") do
      assert Provider::Factory.bank_sync_disabled?
      assert_empty Provider::Factory.adapters_for_account_type("Depository")
      assert_empty Provider::Factory.connection_configs_for_account_type(account_type: "Depository", family: families(:dylan_family))
    end
  end
end
