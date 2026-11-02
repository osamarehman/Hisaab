# One forwarded bank alert email and what became of it. A parsed alert on a
# recognised account becomes a *pending* transaction (extra.email.pending), so
# it stays out of balances, reports and budgets until the user approves it;
# rejecting deletes it. Forwarded mail can't be authenticated against the bank,
# which is why nothing is ever posted without that review.
class BankAlert < ApplicationRecord
  STATUSES = %w[pending needs_account unparsed ignored approved rejected].freeze
  DIRECTIONS = %w[in out].freeze

  belongs_to :family
  belongs_to :inbound_email, class_name: "ActionMailbox::InboundEmail", optional: true
  belongs_to :account, optional: true
  belongs_to :entry, optional: true

  validates :status, inclusion: { in: STATUSES }
  validates :direction, inclusion: { in: DIRECTIONS }, allow_nil: true
  validates :message_id, :received_at, presence: true

  scope :newest_first, -> { order(received_at: :desc, created_at: :desc) }

  class InvalidTransition < StandardError; end

  # Files a parsed alert: a pending transaction when exactly one account
  # carries its last four digits, otherwise it waits for the user to pick one.
  def file!(parsed)
    assign_attributes(parsed.to_h.slice(:parser, :amount, :currency, :direction, :last4, :occurred_at, :payee))
    matches = last4.present? ? family.accounts.visible.where(number_last4: last4).to_a : []

    transaction do
      if matches.one?
        self.account = matches.first
        self.status = "pending"
        save!
        update!(entry: create_entry!(pending: true))
      else
        self.status = "needs_account"
        save!
      end
    end
  end

  # Clears the pending flag, or for an alert with no account, posts it to the
  # chosen one and remembers that account's last four digits.
  def approve!(account: nil, category: nil, name: nil)
    transaction do
      case status
      when "pending"
        raise InvalidTransition, "The transaction for this alert no longer exists" unless entry
      when "needs_account"
        raise InvalidTransition, "Choose an account for this alert" unless account
        account.update!(number_last4: last4) if last4.present? && account.number_last4.blank?
        update!(account: account, entry: create_entry!(pending: false, on: account))
      else
        raise InvalidTransition, "A #{status} alert can't be approved"
      end

      txn = entry.transaction
      extra = (txn.extra || {}).deep_dup
      extra["email"] = (extra["email"] || {}).merge("pending" => false)
      txn.update!(extra: extra, category: category || txn.category)
      entry.update!(name: name) if name.present?
      update!(status: "approved")
    end
    entry.account.sync_later
    self
  end

  def reject!
    raise InvalidTransition, "A #{status} alert can't be rejected" unless status.in?(%w[pending needs_account unparsed])

    transaction do
      entry&.destroy!
      update!(status: "rejected", entry: nil)
    end
    self
  end

  private
    # Money out is a positive amount in Sure's sign convention.
    def create_entry!(pending:, on: account)
      on.entries.create!(
        date: (occurred_at || received_at).in_time_zone(family.timezone.presence || Time.zone).to_date,
        amount: direction == "out" ? amount : -amount,
        currency: currency.presence || on.currency,
        name: payee.presence || subject.presence || I18n.t("bank_alerts.default_name"),
        entryable: Transaction.new(
          extra: { "email" => { "pending" => pending, "bank_alert_id" => id, "from" => from_address, "subject" => subject } }
        )
      )
    end
end
