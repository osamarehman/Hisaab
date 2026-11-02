require "test_helper"

class Api::V1::BankAlertsApiTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    @family = @user.family
    @user.api_keys.active.destroy_all
    @key = ApiKey.create!(user: @user, name: "Alerts", scopes: [ "read_write" ], display_key: "test_rw_#{SecureRandom.hex(8)}", source: "mobile")
    Redis.new.del("api_rate_limit:#{@key.id}")
    @account = accounts(:depository)
  end

  test "the inbox is created on first read and can be rotated" do
    get "/api/v1/email_inbox", headers: api_headers(@key)
    assert_response :ok
    address = response.parsed_body["address"]
    assert_match(/\Aalerts\+[0-9a-z]{20}@#{Regexp.escape(EmailInbox.domain)}\z/, address)
    assert_nil response.parsed_body["confirmation"]
    assert_equal [], response.parsed_body["senders"]

    post "/api/v1/email_inbox/rotate", headers: api_headers(@key)
    assert_response :ok
    assert_not_equal address, response.parsed_body["address"]
  end

  test "senders can be added, listed and removed, and bad patterns are refused" do
    post "/api/v1/email_senders", params: { pattern: " @MeezanBank.com " }, headers: api_headers(@key)
    assert_response :created
    sender = response.parsed_body
    assert_equal "@meezanbank.com", sender["pattern"]

    post "/api/v1/email_senders", params: { pattern: "not an address" }, headers: api_headers(@key)
    assert_response :unprocessable_entity
    assert_equal "validation_failed", response.parsed_body["error"]

    get "/api/v1/email_senders", headers: api_headers(@key)
    assert_equal [ "@meezanbank.com" ], response.parsed_body["senders"].map { |s| s["pattern"] }

    delete "/api/v1/email_senders/#{sender["id"]}", headers: api_headers(@key)
    assert_response :no_content
  end

  test "alerts are listed by status and can be approved onto an account or rejected" do
    waiting = alert!(status: "needs_account")
    other = alert!(status: "unparsed")

    get "/api/v1/bank_alerts", params: { status: "needs_account" }, headers: api_headers(@key)
    assert_response :ok
    assert_equal [ waiting.id ], response.parsed_body["bank_alerts"].map { |a| a["id"] }
    assert_equal "10000.0", response.parsed_body["bank_alerts"].first["amount"]

    post "/api/v1/bank_alerts/#{waiting.id}/approve", params: { account_id: @account.id }, headers: api_headers(@key)
    assert_response :ok
    assert_equal "approved", response.parsed_body["status"]
    assert_equal @account.id, response.parsed_body.dig("account", "id")
    assert response.parsed_body["transaction_id"]

    post "/api/v1/bank_alerts/#{other.id}/approve", headers: api_headers(@key)
    assert_response :unprocessable_entity

    post "/api/v1/bank_alerts/#{other.id}/reject", headers: api_headers(@key)
    assert_equal "rejected", response.parsed_body["status"]

    get "/api/v1/bank_alerts", params: { status: "bogus" }, headers: api_headers(@key)
    assert_response :unprocessable_entity
  end

  test "another household's alerts are not reachable" do
    foreign = families(:empty).bank_alerts.create!(message_id: "x", status: "needs_account", received_at: Time.current)

    post "/api/v1/bank_alerts/#{foreign.id}/reject", headers: api_headers(@key)
    assert_response :not_found
  end

  test "read-only keys can read but not change" do
    @key.update!(scopes: [ "read" ])
    get "/api/v1/email_inbox", headers: api_headers(@key)
    assert_response :ok
    post "/api/v1/email_senders", params: { pattern: "@meezanbank.com" }, headers: api_headers(@key)
    assert_response :forbidden
  end

  test "accounts accept and validate the last four digits" do
    patch "/api/v1/accounts/#{@account.id}", params: { account: { number_last4: "9483" } }, headers: api_headers(@key)
    assert_response :ok
    assert_equal "9483", response.parsed_body["number_last4"]

    patch "/api/v1/accounts/#{@account.id}", params: { account: { number_last4: "94" } }, headers: api_headers(@key)
    assert_response :unprocessable_entity

    patch "/api/v1/accounts/#{@account.id}", params: { account: { number_last4: nil } }, as: :json, headers: api_headers(@key)
    assert_response :ok
    assert_nil response.parsed_body["number_last4"]

    post "/api/v1/accounts", params: { account: { name: "Meezan", accountable_type: "Depository", number_last4: "1234" } }, headers: api_headers(@key)
    assert_response :created
    assert_equal "1234", response.parsed_body["number_last4"]
  end

  private
    def alert!(status:)
      @family.bank_alerts.create!(
        message_id: SecureRandom.hex, status: status, received_at: Time.current, from_address: "no-reply@meezanbank.com",
        subject: "Debit Transaction Alert", parser: "meezan", amount: 10_000, currency: "USD", direction: "out", last4: "9483"
      )
    end
end
