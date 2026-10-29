# frozen_string_literal: true

require "test_helper"

class Api::V1::ReportsControllerTest < ActionDispatch::IntegrationTest
  include EntriesTestHelper

  setup do
    @user = users(:family_admin)
    @family = @user.family
    @api_key = ApiKey.create!(
      user: @user,
      name: "Test Read Key",
      scopes: [ "read" ],
      display_key: "test_ro_#{SecureRandom.hex(8)}",
      source: "mobile"
    )
    Redis.new.del("api_rate_limit:#{@api_key.id}")

    create_transaction(date: Date.new(2020, 3, 2), name: "Groceries", amount: 2500, category: categories(:food_and_drink))
    create_transaction(date: Date.new(2020, 3, 3), name: "Rickshaw", amount: 300)
  end

  test "requires authentication" do
    get api_v1_reports_export_url(format: :pdf), params: period

    assert_response :unauthorized
  end

  test "returns a PDF for a read key" do
    get api_v1_reports_export_url(format: :pdf), params: period, headers: api_headers

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_includes response.headers["Content-Disposition"], "hisaab-report-2020-03-01-to-2020-03-31.pdf"
    assert_equal "private, no-store", response.headers["Cache-Control"]
    text = pdf_text
    assert_includes text, "Hisaab report"
    assert_includes text, "Groceries"
    assert_includes text, "Rickshaw"
  end

  test "filters by label, unlabelled and account" do
    get api_v1_reports_export_url(format: :pdf),
      params: period.merge(category_ids: [ categories(:food_and_drink).id ], include_uncategorized: "false", account_ids: [ accounts(:depository).id ]),
      headers: api_headers

    assert_response :success
    text = pdf_text
    assert_includes text, "Groceries"
    assert_not_includes text, "Rickshaw"
    assert_includes text, "Checking Account"
  end

  test "rejects a missing, reversed or too long period" do
    [ {}, { start_date: "2020-03-31", end_date: "2020-03-01" }, { start_date: "2020-01-01", end_date: "2022-01-01" },
      { start_date: "not-a-date", end_date: "2020-03-31" } ].each do |params|
      get api_v1_reports_export_url(format: :pdf), params: params, headers: api_headers

      assert_response :unprocessable_entity
      assert_equal "invalid_period", JSON.parse(response.body)["error"]
    end
  end

  test "rejects labels and accounts from another household" do
    other_family = families(:empty)
    other_category = other_family.categories.create!(name: "Theirs", color: "#123456")

    get api_v1_reports_export_url(format: :pdf), params: period.merge(category_ids: [ other_category.id ]), headers: api_headers
    assert_response :unprocessable_entity
    assert_equal "invalid_category", JSON.parse(response.body)["error"]

    get api_v1_reports_export_url(format: :pdf), params: period.merge(account_ids: [ "not-a-uuid" ]), headers: api_headers
    assert_response :unprocessable_entity
    assert_equal "invalid_account", JSON.parse(response.body)["error"]
  end

  test "rejects accounts the user cannot see" do
    member_key = ApiKey.create!(user: users(:family_member), name: "Member", scopes: [ "read" ],
      display_key: "test_member_#{SecureRandom.hex(8)}", source: "mobile")

    get api_v1_reports_export_url(format: :pdf), params: period.merge(account_ids: [ accounts(:other_asset).id ]),
      headers: { "X-Api-Key" => member_key.display_key }

    assert_response :unprocessable_entity
    assert_equal "invalid_account", JSON.parse(response.body)["error"]
  end

  private
    def period
      { start_date: "2020-03-01", end_date: "2020-03-31" }
    end

    def api_headers
      { "X-Api-Key" => @api_key.display_key }
    end

    def pdf_text
      PDF::Reader.new(StringIO.new(response.body)).pages.map(&:text).join("\n")
    end
end
