class ApplicationMailbox < ActionMailbox::Base
  # The only mail this app receives is forwarded bank alerts.
  routing all: :bank_alerts
end
