module LegalPagesHelper
  LEGAL_PAGES_UPDATED_ON = Date.new(2026, 10, 28)

  def legal_page_interpolations
    {
      product_name: product_name,
      publisher: Rails.configuration.x.legal_publisher,
      contact_email: Rails.configuration.x.legal_contact_email,
      source_url: Rails.configuration.x.source_code_url
    }
  end
end
