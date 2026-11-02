# Picks the parser for a bank alert email by its sender and reads the alert's
# figures out of the email's plain text. Nil when no parser recognises it.
class BankAlert::Parser
  Parsed = Data.define(:parser, :amount, :currency, :direction, :last4, :occurred_at, :payee)

  PARSERS = [ BankAlert::Parsers::Meezan ].freeze

  def self.parse(from:, text:, sent_at:)
    parser = PARSERS.find { |candidate| candidate.handles?(from) }
    parser&.new(text: text, sent_at: sent_at)&.parse
  end
end
