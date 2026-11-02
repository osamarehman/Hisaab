# frozen_string_literal: true

json.senders @senders, partial: "api/v1/email_senders/email_sender", as: :email_sender
