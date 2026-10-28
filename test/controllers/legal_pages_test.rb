require "test_helper"

class LegalPagesTest < ActionDispatch::IntegrationTest
  test "privacy policy is public and names the publisher, contact and AI processor" do
    get privacy_path

    assert_response :success
    assert_select "h1", text: I18n.t("pages.privacy.heading")
    assert_match Rails.configuration.x.legal_publisher, response.body
    assert_select "a[href=?]", "mailto:#{Rails.configuration.x.legal_contact_email}"
    assert_match "OpenRouter", response.body
    assert_select "a[href=?]", account_deletion_path
  end

  test "terms are public and link to the source code" do
    get terms_path

    assert_response :success
    assert_select "h1", text: I18n.t("pages.terms.heading")
    assert_select "a[href=?]", Rails.configuration.x.source_code_url
  end

  test "account deletion page is public and explains every route" do
    get account_deletion_path

    assert_response :success
    assert_select "h1", text: I18n.t("pages.account_deletion.heading", product_name: Rails.configuration.x.product_name)
    assert_select "section#app ol li", count: 3
    assert_select "section#web ol li", count: 3
    assert_match Rails.configuration.x.legal_contact_email, response.body
  end

  test "sign-up page links to the terms and privacy policy" do
    get new_registration_path

    assert_response :success
    assert_select "form a[href=?]", terms_path
    assert_select "form a[href=?]", privacy_path
  end
end
