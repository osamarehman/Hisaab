# An address, or a whole domain written "@bank.com", whose mail the household's
# inbox accepts. Forwarded mail can't be authenticated against the bank, so this
# list plus the inbox's secret address is what keeps strangers' mail out.
class EmailSender < ApplicationRecord
  ADDRESS = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/
  DOMAIN = /\A@[^@\s]+\.[^@\s]+\z/

  belongs_to :family

  normalizes :pattern, with: ->(pattern) { pattern.to_s.strip.downcase }
  validates :pattern, presence: true, uniqueness: { scope: :family_id }
  validate :pattern_is_address_or_domain

  def matches?(address)
    address = address.to_s.strip.downcase
    domain? ? address.end_with?(pattern) : address == pattern
  end

  def domain?
    pattern.start_with?("@")
  end

  private
    def pattern_is_address_or_domain
      return if pattern.blank? || pattern.match?(ADDRESS) || pattern.match?(DOMAIN)

      errors.add(:pattern, "must be an email address or a domain like @bank.com")
    end
end
