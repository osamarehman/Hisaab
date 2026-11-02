class BankAlertsMailbox < ApplicationMailbox
  def process
    BankAlert::Receiver.new(mail, inbound_email: inbound_email).call
  end
end
