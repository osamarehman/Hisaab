# The household's private forwarding address for bank alert emails, the Gmail
# forwarding confirmation, the allowed senders and the latest alerts.
class Api::V1::EmailInboxesController < Api::V1::BaseController
  before_action -> { authorize_scope!(:read) }, only: :show
  before_action -> { authorize_scope!(:read_write) }, :reject_guest_writes!, only: :rotate

  def show
    render_inbox
  end

  # A new address; mail to the old one is no longer accepted.
  def rotate
    inbox.rotate!
    render_inbox
  end

  private
    def inbox
      @inbox ||= family.email_inbox || family.create_email_inbox!
    rescue ActiveRecord::RecordNotUnique
      family.reload.email_inbox
    end

    def family
      current_resource_owner.family
    end

    def render_inbox
      @inbox = inbox
      @senders = family.email_senders.order(:created_at)
      @alerts = family.bank_alerts.newest_first.includes(:account).limit(20)
      render :show
    end
end
