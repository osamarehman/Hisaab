# frozen_string_literal: true

require "test_helper"

class Api::V1::TransactionAttachmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    @transaction = @user.family.transactions.first

    @user.api_keys.active.destroy_all

    @api_key = ApiKey.create!(
      user: @user,
      name: "Test Read-Write Key",
      scopes: [ "read_write" ],
      display_key: "test_rw_#{SecureRandom.hex(8)}"
    )
    @read_only_api_key = ApiKey.create!(
      user: @user,
      name: "Test Read-Only Key",
      scopes: [ "read" ],
      display_key: "test_ro_#{SecureRandom.hex(8)}",
      source: "mobile"
    )

    Redis.new.del("api_rate_limit:#{@api_key.id}")
    Redis.new.del("api_rate_limit:#{@read_only_api_key.id}")
  end

  test "uploads attachments and returns the transaction" do
    assert_difference "@transaction.attachments.count", 2 do
      post api_v1_transaction_attachments_url(@transaction),
        params: { attachments: [ fixture_file_upload("square-placeholder.png", "image/png"), fixture_file_upload("test.txt", "application/pdf") ] },
        headers: api_headers(@api_key)
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal @transaction.id, body["id"]
    assert_equal %w[square-placeholder.png test.txt], body["attachments"].map { |attachment| attachment["filename"] }.sort
  end

  test "rejects files of an unsupported type" do
    assert_no_difference "@transaction.attachments.count" do
      post api_v1_transaction_attachments_url(@transaction),
        params: { attachments: [ fixture_file_upload("test.txt", "text/plain") ] },
        headers: api_headers(@api_key)
    end

    assert_response :unprocessable_entity
    assert_equal "validation_failed", JSON.parse(response.body)["error"]
  end

  test "rejects uploads past the per-transaction limit" do
    Transaction::MAX_ATTACHMENTS_PER_TRANSACTION.times do |index|
      @transaction.attachments.attach(io: StringIO.new("receipt"), filename: "bill-#{index}.jpg", content_type: "image/jpeg")
    end

    assert_no_difference "@transaction.attachments.count" do
      post api_v1_transaction_attachments_url(@transaction),
        params: { attachments: [ fixture_file_upload("square-placeholder.png", "image/png") ] },
        headers: api_headers(@api_key)
    end

    assert_response :unprocessable_entity
  end

  test "rejects a request without files" do
    post api_v1_transaction_attachments_url(@transaction), headers: api_headers(@api_key)

    assert_response :unprocessable_entity
  end

  test "rejects uploads with a read-only key" do
    assert_no_difference "@transaction.attachments.count" do
      post api_v1_transaction_attachments_url(@transaction),
        params: { attachments: [ fixture_file_upload("square-placeholder.png", "image/png") ] },
        headers: api_headers(@read_only_api_key)
    end

    assert_response :forbidden
  end

  test "requires authentication" do
    post api_v1_transaction_attachments_url(@transaction),
      params: { attachments: [ fixture_file_upload("square-placeholder.png", "image/png") ] }

    assert_response :unauthorized
  end

  test "returns 404 for another family's transaction" do
    other_account = families(:empty).accounts.create!(name: "Other", balance: 0, currency: "USD", accountable: Depository.new)
    other_entry = other_account.entries.create!(name: "Other", date: Date.current, amount: 10, currency: "USD", entryable: Transaction.new)

    post api_v1_transaction_attachments_url(other_entry.entryable),
      params: { attachments: [ fixture_file_upload("square-placeholder.png", "image/png") ] },
      headers: api_headers(@api_key)

    assert_response :not_found
  end

  test "streams an attachment with API auth" do
    attachment = attach_receipt

    get api_v1_transaction_attachment_url(@transaction, attachment), headers: api_headers(@read_only_api_key)

    assert_response :success
    assert_equal "receipt", response.body
    assert_equal "image/jpeg", response.media_type
  end

  test "deletes an attachment" do
    attachment = attach_receipt

    assert_difference "@transaction.attachments.count", -1 do
      delete api_v1_transaction_attachment_url(@transaction, attachment), headers: api_headers(@api_key)
    end

    assert_response :no_content
  end

  test "rejects delete with a read-only key" do
    attachment = attach_receipt

    assert_no_difference "@transaction.attachments.count" do
      delete api_v1_transaction_attachment_url(@transaction, attachment), headers: api_headers(@read_only_api_key)
    end

    assert_response :forbidden
  end

  test "returns 404 for an unknown attachment" do
    delete api_v1_transaction_attachment_url(@transaction, SecureRandom.uuid), headers: api_headers(@api_key)

    assert_response :not_found
  end

  private

    def attach_receipt
      @transaction.attachments.attach(io: StringIO.new("receipt"), filename: "bill.jpg", content_type: "image/jpeg")
      @transaction.attachments.last
    end

    def api_headers(api_key)
      { "X-Api-Key" => api_key.display_key }
    end
end
