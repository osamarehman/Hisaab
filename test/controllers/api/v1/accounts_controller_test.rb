# frozen_string_literal: true

require "test_helper"

class Api::V1::AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin) # dylan_family user
    @other_family_user = users(:family_member)
    @other_family_user.update!(family: families(:empty))

    @user.api_keys.active.destroy_all
    @api_key = ApiKey.create!(
      user: @user,
      name: "Test Read Key",
      scopes: [ "read" ],
      source: "web",
      display_key: "test_read_#{SecureRandom.hex(8)}"
    )

    @other_family_user.api_keys.active.destroy_all
    @other_family_api_key = ApiKey.create!(
      user: @other_family_user,
      name: "Other Family Read Key",
      scopes: [ "read" ],
      source: "web",
      display_key: "other_family_read_#{SecureRandom.hex(8)}"
    )
  end

  test "should require authentication" do
    get "/api/v1/accounts"
    assert_response :unauthorized

    response_body = JSON.parse(response.body)
    assert_equal "unauthorized", response_body["error"]
  end

  test "should require read_accounts scope" do
    api_key_without_read = ApiKey.new(
      user: @user,
      name: "No Read Key",
      scopes: [],
      source: "web",
      display_key: "no_read_#{SecureRandom.hex(8)}"
    )
    # Valid persisted API keys can only be read/read_write; this intentionally
    # bypasses validations to exercise the runtime insufficient-scope guard.
    api_key_without_read.save!(validate: false)

    get "/api/v1/accounts", params: {}, headers: api_headers(api_key_without_read)

    assert_response :forbidden
    response_body = JSON.parse(response.body)
    assert_equal "insufficient_scope", response_body["error"]
  ensure
    api_key_without_read&.destroy
  end

  test "should return user's family accounts successfully" do
    get "/api/v1/accounts", params: {}, headers: api_headers(@api_key)

    assert_response :success
    response_body = JSON.parse(response.body)

    # Should have accounts array
    assert response_body.key?("accounts")
    assert response_body["accounts"].is_a?(Array)

    # Should have pagination metadata
    assert response_body.key?("pagination")
    assert response_body["pagination"].key?("page")
    assert response_body["pagination"].key?("per_page")
    assert response_body["pagination"].key?("total_count")
    assert response_body["pagination"].key?("total_pages")

    # All accounts should belong to user's family
    response_body["accounts"].each do |account|
      # We'll validate this by checking the user's family has these accounts
      family_account_names = @user.family.accounts.pluck(:name)
      assert_includes family_account_names, account["name"]
    end
  end

  test "should only return active accounts" do
    # Make one account inactive
    inactive_account = accounts(:depository)
    inactive_account.disable!

    get "/api/v1/accounts", params: {}, headers: api_headers(@api_key)

    assert_response :success
    response_body = JSON.parse(response.body)

    # Should not include the inactive account
    account_names = response_body["accounts"].map { |a| a["name"] }
    assert_not_includes account_names, inactive_account.name
  end

  test "should include disabled accounts when requested" do
    inactive_account = accounts(:depository)
    inactive_account.disable!

    get "/api/v1/accounts", params: { include_disabled: true }, headers: api_headers(@api_key)

    assert_response :success
    response_body = JSON.parse(response.body)

    account = response_body["accounts"].find { |account_data| account_data["id"] == inactive_account.id }
    assert_not_nil account
    assert_equal "disabled", account["status"]
  end

  test "should show active account" do
    account = accounts(:depository)

    get "/api/v1/accounts/#{account.id}", headers: api_headers(@api_key)

    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal account.id, response_body["id"]
    assert_equal account.status, response_body["status"]
    assert_equal account.balance_money.format, response_body["balance"]
    assert_equal money_cents(account.balance_money), response_body["balance_cents"]
    assert_equal account.cash_balance_money.format, response_body["cash_balance"]
    assert_equal money_cents(account.cash_balance_money), response_body["cash_balance_cents"]
    assert_nullable_equal account.subtype, response_body["subtype"]
    assert response_body.key?("institution_name")
    assert response_body.key?("institution_domain")
    assert_nullable_equal account.institution_name, response_body["institution_name"]
    assert_nullable_equal account.institution_domain, response_body["institution_domain"]
    assert_equal account.created_at.iso8601, response_body["created_at"]
    assert_equal account.updated_at.iso8601, response_body["updated_at"]
  end

  test "should return 404 for unknown account on show" do
    get "/api/v1/accounts/#{SecureRandom.uuid}", headers: api_headers(@api_key)

    assert_response :not_found
    response_body = JSON.parse(response.body)
    assert_equal "not_found", response_body["error"]
  end

  test "should return 404 for malformed account id on show" do
    get "/api/v1/accounts/not-a-uuid", headers: api_headers(@api_key)

    assert_response :not_found
    response_body = JSON.parse(response.body)
    assert_equal "not_found", response_body["error"]
    assert_equal "Account not found", response_body["message"]
  end

  test "should require authentication on show" do
    account = accounts(:depository)

    get "/api/v1/accounts/#{account.id}"

    assert_response :unauthorized
    response_body = JSON.parse(response.body)
    assert_equal "unauthorized", response_body["error"]
  end

  test "should require read scope on show" do
    account = accounts(:depository)
    api_key_without_read = ApiKey.new(
      user: @user,
      name: "No Read Show Key",
      scopes: [],
      source: "web",
      display_key: "no_read_show_#{SecureRandom.hex(8)}"
    )
    # Valid persisted API keys can only be read/read_write; this intentionally
    # bypasses validations to exercise the runtime insufficient-scope guard.
    api_key_without_read.save!(validate: false)

    get "/api/v1/accounts/#{account.id}", headers: api_headers(api_key_without_read)

    assert_response :forbidden
    response_body = JSON.parse(response.body)
    assert_equal "insufficient_scope", response_body["error"]
  ensure
    api_key_without_read&.destroy
  end

  test "should hide disabled account by default on show" do
    inactive_account = accounts(:depository)
    inactive_account.disable!

    get "/api/v1/accounts/#{inactive_account.id}", headers: api_headers(@api_key)

    assert_response :not_found
  end

  test "should show disabled account when requested" do
    inactive_account = accounts(:depository)
    inactive_account.disable!

    get "/api/v1/accounts/#{inactive_account.id}",
        params: { include_disabled: true },
        headers: api_headers(@api_key)

    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal inactive_account.id, response_body["id"]
    assert_equal "disabled", response_body["status"]
  end

  test "should expose subtype across account types" do
    expected_subtypes = {
      accounts(:depository) => "checking",
      accounts(:credit_card) => "credit_card",
      accounts(:investment) => "brokerage",
      accounts(:loan) => "mortgage",
      accounts(:property) => "single_family_home",
      accounts(:vehicle) => "sedan",
      accounts(:crypto) => "exchange",
      accounts(:other_asset) => "collectible",
      accounts(:other_liability) => "personal_debt"
    }

    expected_subtypes.each { |account, subtype| account.accountable.update!(subtype: subtype) }

    expected_subtypes.each do |account, subtype|
      get "/api/v1/accounts/#{account.id}", headers: api_headers(@api_key)

      assert_response :success
      assert_equal subtype, JSON.parse(response.body)["subtype"]
    end
  end

  test "should not return other family's accounts" do
    get "/api/v1/accounts", params: {}, headers: api_headers(@other_family_api_key)

    assert_response :success
    response_body = JSON.parse(response.body)

    # Should return empty array since other family has no accounts in fixtures
    assert_equal [], response_body["accounts"]
    assert_equal 0, response_body["pagination"]["total_count"]
  end

  test "should handle pagination parameters" do
    # Test with pagination params
    get "/api/v1/accounts", params: { page: 1, per_page: 2 }, headers: api_headers(@api_key)

    assert_response :success
    response_body = JSON.parse(response.body)

    # Should respect per_page limit
    assert response_body["accounts"].length <= 2
    assert_equal 1, response_body["pagination"]["page"]
    assert_equal 2, response_body["pagination"]["per_page"]
  end

  test "should return proper account data structure" do
    get "/api/v1/accounts", params: {}, headers: api_headers(@api_key)

    assert_response :success
    response_body = JSON.parse(response.body)

    # Should have at least one account from fixtures
    assert response_body["accounts"].length > 0

    account = response_body["accounts"].first

    # Check required fields are present
    required_fields = %w[id name balance balance_cents cash_balance cash_balance_cents currency classification account_type]
    required_fields.each do |field|
      assert account.key?(field), "Account should have #{field} field"
    end

    # Check data types
    assert account["id"].is_a?(String), "ID should be string (UUID)"
    assert account["name"].is_a?(String), "Name should be string"
    assert account["balance"].is_a?(String), "Balance should be string (money)"
    assert account["balance_cents"].is_a?(Integer), "Balance cents should be integer"
    assert account["cash_balance_cents"].is_a?(Integer), "Cash balance cents should be integer"
    assert account["currency"].is_a?(String), "Currency should be string"
    assert %w[asset liability].include?(account["classification"]), "Classification should be asset or liability"
  end

  test "should handle invalid pagination parameters gracefully" do
    # Test with invalid page number
    get "/api/v1/accounts", params: { page: -1, per_page: "invalid" }, headers: api_headers(@api_key)

    # Should still return success with default pagination
    assert_response :success
    response_body = JSON.parse(response.body)

    # Should have pagination info (with defaults applied)
    assert response_body.key?("pagination")
    assert response_body["pagination"]["page"] >= 1
    assert response_body["pagination"]["per_page"] > 0
  end

  test "should sort accounts alphabetically" do
    get "/api/v1/accounts", params: {}, headers: api_headers(@api_key)

    assert_response :success
    response_body = JSON.parse(response.body)

    # Should be sorted alphabetically by name
    account_names = response_body["accounts"].map { |a| a["name"] }
    assert_equal account_names.sort, account_names
  end

  test "create requires read_write scope" do
    assert_no_difference "Account.count" do
      post "/api/v1/accounts", params: create_params, headers: api_headers(@api_key)
    end

    assert_response :forbidden
    assert_equal "insufficient_scope", JSON.parse(response.body)["error"]
  end

  test "create requires authentication" do
    post "/api/v1/accounts", params: create_params

    assert_response :unauthorized
  end

  test "create makes a manual depository with an opening balance owned by the caller" do
    assert_difference "Account.count", 1 do
      post "/api/v1/accounts",
           params: create_params(subtype: "savings", balance: "25000.50"),
           headers: api_headers(write_key)
    end

    assert_response :created
    body = JSON.parse(response.body)
    account = Account.find(body["id"])

    assert_equal "Meezan savings", body["name"]
    assert_equal "depository", body["account_type"]
    assert_equal "savings", body["subtype"]
    assert_equal @user.family.currency, body["currency"]
    assert_equal BigDecimal("25000.50"), account.balance
    assert_equal @user, account.owner
    assert_equal :owner, account.permission_for(@user)
    assert account.manual?

    opening = account.entries.valuations.order(:date).first
    assert_not_nil opening
    assert_equal BigDecimal("25000.50"), opening.amount
    assert_equal Date.current - 2.years, opening.date
  end

  test "create honours opening_balance_date and currency" do
    post "/api/v1/accounts",
         params: create_params(currency: "usd", opening_balance_date: "2026-01-15"),
         headers: api_headers(write_key)

    assert_response :created
    account = Account.find(JSON.parse(response.body)["id"])
    assert_equal "USD", account.currency
    assert_equal Date.new(2026, 1, 15), account.entries.valuations.order(:date).first.date
  end

  test "create stores a liability with the amount owed" do
    post "/api/v1/accounts",
         params: { account: { name: "Loan from Bilal", accountable_type: "OtherLiability", balance: "50000" } },
         headers: api_headers(write_key)

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "liability", body["classification"]
    assert_equal BigDecimal("50000"), Account.find(body["id"]).balance
  end

  test "create defaults a missing balance to zero" do
    post "/api/v1/accounts",
         params: { account: { name: "Cash in hand", accountable_type: "Depository", subtype: "cash" } },
         headers: api_headers(write_key)

    assert_response :created
    assert_equal 0, Account.find(JSON.parse(response.body)["id"]).balance
  end

  test "create rejects account types outside the allow-list" do
    %w[Investment Property Crypto Vehicle Bogus].each do |type|
      assert_no_difference "Account.count" do
        post "/api/v1/accounts",
             params: create_params(accountable_type: type),
             headers: api_headers(write_key)
      end
      assert_response :unprocessable_entity
      assert_equal "validation_failed", JSON.parse(response.body)["error"]
    end
  end

  test "create rejects invalid params" do
    [
      create_params(name: ""),
      create_params(subtype: "mortgage"),
      create_params(balance: "lots"),
      create_params(currency: "ZZZ"),
      create_params(opening_balance_date: "15/01/2026"),
      create_params(opening_balance_date: (Date.current + 1.day).iso8601)
    ].each do |params|
      assert_no_difference "Account.count" do
        post "/api/v1/accounts", params: params, headers: api_headers(write_key)
      end
      assert_response :unprocessable_entity, "expected 422 for #{params.inspect}"
    end
  end

  test "create rejects a missing account payload" do
    post "/api/v1/accounts", params: {}, headers: api_headers(write_key)

    assert_response :unprocessable_entity
  end

  test "guests cannot create accounts" do
    guest = @user.family.users.create!(
      email: "guest-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      role: :guest
    )

    assert_no_difference "Account.count" do
      post "/api/v1/accounts", params: create_params, headers: api_headers(write_key(guest))
    end

    assert_response :forbidden
  end

  test "update renames an account" do
    account = accounts(:depository)

    patch "/api/v1/accounts/#{account.id}",
          params: { account: { name: "HBL current" } },
          headers: api_headers(write_key)

    assert_response :success
    assert_equal "HBL current", JSON.parse(response.body)["name"]
    assert_equal "HBL current", account.reload.name
  end

  test "update sets the current balance like the web" do
    account = accounts(:depository)

    patch "/api/v1/accounts/#{account.id}",
          params: { account: { balance: "1234.56" } },
          headers: api_headers(write_key)

    assert_response :success
    assert_equal BigDecimal("1234.56"), account.reload.balance
  end

  test "update records today's valuation for a non-cash account" do
    account = accounts(:other_asset)

    patch "/api/v1/accounts/#{account.id}",
          params: { account: { balance: "1234.56" } },
          headers: api_headers(write_key)

    assert_response :success
    assert_equal BigDecimal("1234.56"), account.reload.balance
    assert_equal BigDecimal("1234.56"), account.entries.valuations.find_by!(date: Date.current).amount
  end

  test "update rejects invalid params" do
    account = accounts(:depository)
    original_name = account.name

    patch "/api/v1/accounts/#{account.id}", params: { account: { name: " " } }, headers: api_headers(write_key)
    assert_response :unprocessable_entity

    patch "/api/v1/accounts/#{account.id}", params: { account: { balance: "abc" } }, headers: api_headers(write_key)
    assert_response :unprocessable_entity

    assert_equal original_name, account.reload.name
  end

  test "update requires write permission on the account" do
    account = accounts(:credit_card)
    member = member_sharing(account, permission: "read_only")

    patch "/api/v1/accounts/#{account.id}",
          params: { account: { name: "Mine now" } },
          headers: api_headers(write_key(member))

    assert_response :forbidden
    assert_not_equal "Mine now", account.reload.name
  end

  test "update allows full_control shares" do
    account = accounts(:depository)
    member = member_sharing(account, permission: "full_control")

    patch "/api/v1/accounts/#{account.id}",
          params: { account: { name: "Shared rename" } },
          headers: api_headers(write_key(member))

    assert_response :success
  end

  test "update requires read_write scope" do
    patch "/api/v1/accounts/#{accounts(:depository).id}",
          params: { account: { name: "Nope" } },
          headers: api_headers(@api_key)

    assert_response :forbidden
  end

  test "update returns 404 for other family accounts and bad ids" do
    patch "/api/v1/accounts/#{accounts(:depository).id}",
          params: { account: { name: "Nope" } },
          headers: api_headers(write_key(@other_family_user))
    assert_response :not_found

    patch "/api/v1/accounts/not-a-uuid", params: { account: { name: "Nope" } }, headers: api_headers(write_key)
    assert_response :not_found
  end

  test "destroy schedules deletion of a manual account" do
    account = accounts(:other_asset)

    assert_enqueued_with(job: DestroyJob) do
      delete "/api/v1/accounts/#{account.id}", headers: api_headers(write_key)
    end

    assert_response :no_content
    assert account.reload.pending_deletion?

    delete "/api/v1/accounts/#{account.id}", headers: api_headers(write_key)
    assert_response :not_found
  end

  test "destroy refuses linked accounts" do
    account = accounts(:connected)

    delete "/api/v1/accounts/#{account.id}", headers: api_headers(write_key)

    assert_response :unprocessable_entity
    assert_not account.reload.pending_deletion?
  end

  test "destroy requires write permission and scope" do
    member = member_sharing(accounts(:credit_card), permission: "read_only")
    delete "/api/v1/accounts/#{accounts(:credit_card).id}", headers: api_headers(write_key(member))
    assert_response :forbidden

    delete "/api/v1/accounts/#{accounts(:depository).id}", headers: api_headers(@api_key)
    assert_response :forbidden

    assert_not accounts(:credit_card).reload.pending_deletion?
    assert_not accounts(:depository).reload.pending_deletion?
  end

  private

    def api_headers(api_key)
      { "X-Api-Key" => api_key.plain_key }
    end

    def write_key(user = @user)
      @write_keys ||= {}
      @write_keys[user.id] ||= ApiKey.create!(
        user: user,
        name: "Test Write Key",
        scopes: [ "read_write" ],
        source: "mobile",
        display_key: "test_write_#{SecureRandom.hex(8)}"
      )
    end

    # setup moves family_member to another family, so share with a fresh member.
    def member_sharing(account, permission:)
      member = @user.family.users.create!(
        email: "member-#{SecureRandom.hex(4)}@example.com",
        password: "password123",
        role: :member
      )
      account.account_shares.where(user: member).destroy_all
      account.share_with!(member, permission: permission)
      member
    end

    def create_params(overrides = {})
      {
        account: {
          name: "Meezan savings",
          accountable_type: "Depository",
          subtype: "checking",
          balance: "1000"
        }.merge(overrides)
      }
    end

    def money_cents(money)
      (money.amount * money.currency.minor_unit_conversion).round(0).to_i
    end

    def assert_nullable_equal(expected, actual)
      expected.nil? ? assert_nil(actual) : assert_equal(expected, actual)
    end
end
