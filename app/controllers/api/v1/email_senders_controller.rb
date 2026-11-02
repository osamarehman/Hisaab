# Senders whose mail the household's bank alert inbox accepts.
class Api::V1::EmailSendersController < Api::V1::BaseController
  before_action -> { authorize_scope!(:read) }, only: :index
  before_action -> { authorize_scope!(:read_write) }, :reject_guest_writes!, only: %i[create destroy]

  def index
    @senders = family.email_senders.order(:created_at)
    render :index
  end

  def create
    @sender = family.email_senders.new(pattern: params[:pattern])
    if @sender.save
      render :show, status: :created
    else
      render json: { error: "validation_failed", message: @sender.errors.full_messages.to_sentence, errors: @sender.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  def destroy
    family.email_senders.find(params[:id]).destroy!
    head :no_content
  end

  private
    def family
      current_resource_owner.family
    end
end
