require "test_helper"

class BankAlertIngressTest < ActionDispatch::IntegrationTest
  setup { ActionMailbox.ingress = :relay }
  teardown { ActionMailbox.ingress = nil }

  test "the relay ingress accepts mail only with the shared password" do
    raw = "From: no-reply@meezanbank.com\r\nTo: x@#{EmailInbox.domain}\r\nSubject: Hi\r\nMessage-ID: <a@b>\r\n\r\nHello"
    url = "/rails/action_mailbox/relay/inbound_emails"

    with_env_overrides(RAILS_INBOUND_EMAIL_PASSWORD: "secret") do
      post url, params: raw, headers: { "Content-Type" => "message/rfc822", "Authorization" => basic("wrong") }
      assert_response :unauthorized

      assert_difference -> { ActionMailbox::InboundEmail.count } do
        post url, params: raw, headers: { "Content-Type" => "message/rfc822", "Authorization" => basic("secret") }
      end
      assert_response :no_content
    end
  end

  private
    def basic(password)
      ActionController::HttpAuthentication::Basic.encode_credentials("actionmailbox", password)
    end
end
