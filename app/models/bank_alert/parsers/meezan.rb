# Meezan Bank's "Debit/Credit Transaction Alert" emails, e.g.
#   PKR 10,000.00 sent from your account xxx9483 ... Beneficiary Account
#   Title: : O.REHMAN Branch : SADDAR BR HYD Transaction Date : 02-Nov-2026
#   Transaction Time : 18:05
class BankAlert::Parsers::Meezan
  SENDER_DOMAIN = "@meezanbank.com".freeze
  # The alert states local bank time, whatever zone the household is set to.
  TIME_ZONE = "Asia/Karachi".freeze
  AMOUNT = /\b(PKR|USD|EUR|GBP|AED|SAR)\s*([\d,]+(?:\.\d{1,2})?)/i
  OUT = /\b(?:sent|debited|withdrawn|paid|transferred)\b/i
  IN = /\b(?:received|credited|deposited)\b/i
  LAST4 = /\baccount\s+(?:no\.?\s*|number\s*)?[x*]+(\d{4})\b/i
  # A label's value runs until the next label; the email lays them out inline.
  LABELS = /\s+(?:Beneficiary|Sender|Remitter|Branch|Transaction Date|Transaction Time|Account|Bank|Reference|Channel)\b/i
  PAYEE = /\b(?:Beneficiary|Sender|Remitter)(?:\s+Account)?\s+(?:Title|Name)\s*:[\s:]*/i
  DATE = /Transaction Date\s*:\s*(\d{1,2}-[A-Za-z]{3}-\d{4})/i
  TIME = /Transaction Time\s*:\s*(\d{1,2}:\d{2})/i

  def self.handles?(from)
    from.to_s.downcase.end_with?(SENDER_DOMAIN)
  end

  def initialize(text:, sent_at:)
    @text = text.to_s.squish
    @sent_at = sent_at
  end

  def parse
    currency, amount, direction = transaction_amount
    return nil unless amount

    BankAlert::Parser::Parsed.new(
      parser: "meezan",
      amount: amount.delete(",").to_d,
      currency: currency.upcase,
      direction: direction,
      last4: @text[LAST4, 1],
      occurred_at: occurred_at,
      payee: payee
    )
  end

  private
    # The transaction amount is the first one followed by a direction verb
    # before the next amount: a balance line or the disclaimer also mention
    # amounts and both verbs.
    def transaction_amount
      matches = @text.to_enum(:scan, AMOUNT).map { Regexp.last_match }
      matches.each_with_index do |match, i|
        stop = [ matches[i + 1]&.begin(0) || @text.length, match.end(0) + 120 ].min
        after = @text[match.end(0)...stop]
        out_at = after =~ OUT
        in_at = after =~ IN
        next unless out_at || in_at

        return [ *match.captures, in_at.nil? || (out_at && out_at < in_at) ? "out" : "in" ]
      end
      nil
    end

    def payee
      start = @text =~ PAYEE
      return nil unless start

      rest = @text[(start + @text[PAYEE].length)..]
      rest.split(LABELS, 2).first.to_s.strip.presence
    end

    def occurred_at
      date = @text[DATE, 1]
      return @sent_at unless date

      Time.find_zone!(TIME_ZONE).parse("#{date} #{@text[TIME, 1] || '00:00'}")
    rescue ArgumentError
      @sent_at
    end
end
