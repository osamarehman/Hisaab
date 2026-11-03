# frozen_string_literal: true

require "test_helper"

class Api::V1::FamilySettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    @family = @user.family
    @family.update!(
      currency: "SGD",
      enabled_currencies: [ "USD" ],
      locale: "en",
      date_format: "%Y-%m-%d",
      country: "SG",
      timezone: "Asia/Singapore",
      month_start_day: 15,
      moniker: "Family",
      default_account_sharing: "private"
    )

    @user.api_keys.active.destroy_all
    @api_key = ApiKey.create!(
      user: @user,
      name: "Test Read Key",
      scopes: [ "read" ],
      source: "web",
      display_key: "test_read_#{SecureRandom.hex(8)}"
    )
    Redis.new.del("api_rate_limit:#{@api_key.id}")
  end

  test "shows current family settings snapshot" do
    get api_v1_family_settings_url, headers: api_headers(@api_key)

    assert_response :success
    response_body = JSON.parse(response.body)

    assert_equal @family.id, response_body["id"]
    assert_equal @family.name, response_body["name"]
    assert_equal "SGD", response_body["currency"]
    assert_equal "en", response_body["locale"]
    assert_equal "%Y-%m-%d", response_body["date_format"]
    assert_equal "SG", response_body["country"]
    assert_equal "Asia/Singapore", response_body["timezone"]
    assert_equal 15, response_body["month_start_day"]
    assert_equal "Family", response_body["moniker"]
    assert_equal "private", response_body["default_account_sharing"]
    assert_equal true, response_body["custom_enabled_currencies"]
    assert_equal @family.enabled_currency_codes, response_body["enabled_currencies"]
    assert_equal @family.created_at.change(usec: 0), Time.iso8601(response_body["created_at"])
    assert_equal @family.updated_at.change(usec: 0), Time.iso8601(response_body["updated_at"])
    assert_not response_body.key?("stripe_customer_id")
    assert_not response_body.key?("vector_store_id")
  end

  test "requires authentication" do
    get api_v1_family_settings_url

    assert_response :unauthorized
  end

  test "requires read scope" do
    api_key_without_read = ApiKey.new(
      user: @user,
      name: "No Read Key",
      scopes: [],
      source: "web",
      display_key: "no_read_#{SecureRandom.hex(8)}"
    )
    api_key_without_read.save!(validate: false)

    get api_v1_family_settings_url, headers: api_headers(api_key_without_read)

    assert_response :forbidden
  ensure
    api_key_without_read&.destroy
  end

  test "admin changes the family currency" do
    patch api_v1_family_settings_url, params: { currency: "eur" }, headers: api_headers(write_key_for(@user))

    assert_response :success
    assert_equal "EUR", JSON.parse(response.body)["currency"]
    assert_equal "EUR", @family.reload.currency
  end

  test "rejects an unknown currency" do
    patch api_v1_family_settings_url, params: { currency: "XYZ" }, headers: api_headers(write_key_for(@user))

    assert_response :unprocessable_entity
    assert_equal "validation_failed", JSON.parse(response.body)["error"]
    assert_equal "SGD", @family.reload.currency
  end

  test "rejects a missing currency" do
    patch api_v1_family_settings_url, params: {}, headers: api_headers(write_key_for(@user))

    assert_response :unprocessable_entity
    assert_equal "SGD", @family.reload.currency
  end

  test "members cannot change the family currency" do
    member = users(:family_member)
    assert_equal @family, member.family

    patch api_v1_family_settings_url, params: { currency: "EUR" }, headers: api_headers(write_key_for(member))

    assert_response :forbidden
    assert_equal "SGD", @family.reload.currency
  end

  test "changing the currency requires write scope" do
    patch api_v1_family_settings_url, params: { currency: "EUR" }, headers: api_headers(@api_key)

    assert_response :forbidden
    assert_equal "SGD", @family.reload.currency
  end

  private

    def write_key_for(user)
      user.api_keys.active.destroy_all
      ApiKey.create!(
        user: user,
        name: "Test Write Key",
        scopes: [ "read_write" ],
        source: "web",
        display_key: "test_write_#{SecureRandom.hex(8)}"
      ).tap { |key| Redis.new.del("api_rate_limit:#{key.id}") }
    end

    def api_headers(api_key)
      { "X-Api-Key" => api_key.plain_key }
    end
end
