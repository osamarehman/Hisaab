# A household's private address for forwarded bank alert emails:
# <token>@<BANK_ALERTS_EMAIL_DOMAIN>. The token is the only secret that ties
# mail to a household, so it is random, lowercase (mail clients fold case)
# and can be rotated, which stops the old address at once.
class EmailInbox < ApplicationRecord
  TOKEN_LENGTH = 20
  # Gmail asks the new address to confirm a forwarding rule before it forwards.
  GMAIL_CONFIRMATION_SENDER = "forwarding-noreply@google.com".freeze

  belongs_to :family

  validates :token, presence: true, uniqueness: true
  before_validation :assign_token, on: :create

  def self.domain
    ENV.fetch("BANK_ALERTS_EMAIL_DOMAIN", "in.hisaab.shipdeck.dev").downcase
  end

  # The inbox an email was sent to, from any of its recipient addresses.
  def self.for_recipients(addresses)
    tokens = Array(addresses).filter_map do |address|
      local, domain = address.to_s.downcase.strip.split("@", 2)
      local if domain == self.domain && local.present?
    end
    find_by(token: tokens) if tokens.any?
  end

  def self.generate_token
    SecureRandom.random_number(36**TOKEN_LENGTH).to_s(36).rjust(TOKEN_LENGTH, "0")
  end

  def address
    "#{token}@#{self.class.domain}"
  end

  def rotate!
    update!(token: self.class.generate_token, rotated_at: Time.current)
  end

  # Gmail's confirmation mail carries a numeric code in its subject and a link
  # in its body; either one confirms the rule.
  def record_gmail_confirmation!(subject:, body:)
    update!(
      confirmation_code: subject.to_s[/\(#(\d+)\)/, 1] || body.to_s[/Confirmation code:\s*(\d+)/i, 1],
      confirmation_url: body.to_s[%r{https://mail(?:-settings)?\.google\.com/mail/\S+}]&.delete_suffix("."),
      confirmation_received_at: Time.current
    )
  end

  private
    def assign_token
      self.token ||= self.class.generate_token
      self.rotated_at ||= Time.current
    end
end
