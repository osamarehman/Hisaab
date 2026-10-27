# frozen_string_literal: true

class Api::V1::TransactionAttachmentsController < Api::V1::BaseController
  include Api::V1::TransactionLookup
  include ActiveStorage::Streaming

  UPLOAD_PERMISSIONS = %i[owner full_control read_write].freeze
  DELETE_PERMISSIONS = %i[owner full_control].freeze

  before_action :ensure_read_scope, only: :show
  before_action :ensure_write_scope, only: %i[create destroy]
  before_action :set_transaction
  before_action :set_attachment, only: %i[show destroy]

  def show
    # API keys carry no session, which the blob routes require, so the file is sent here.
    send_blob_stream @attachment.blob, disposition: :inline
  rescue StandardError => e
    Rails.logger.error "TransactionAttachmentsController#show error: #{e.message}"
    # send_blob_stream has already answered; rendering JSON on top would raise DoubleRenderError.
    return if performed?

    render json: { error: "internal_server_error", message: "An unexpected error occurred" }, status: :internal_server_error
  end

  def create
    return render_forbidden unless account_permission.in?(UPLOAD_PERMISSIONS)

    files = attachment_files
    return render_validation_error("No files provided. Send one or more files as attachments[].") if files.empty?

    if @transaction.add_attachments(files)
      @transaction.reload
      render "api/v1/transactions/show", status: :created
    else
      render_validation_error(@transaction.errors.full_messages_for(:attachments).to_sentence)
    end
  rescue StandardError => e
    Rails.logger.error "TransactionAttachmentsController#create error: #{e.message}"
    render json: { error: "internal_server_error", message: "An unexpected error occurred" }, status: :internal_server_error
  end

  def destroy
    return render_forbidden unless account_permission.in?(DELETE_PERMISSIONS)

    @attachment.purge
    head :no_content
  rescue StandardError => e
    Rails.logger.error "TransactionAttachmentsController#destroy error: #{e.message}"
    render json: { error: "internal_server_error", message: "An unexpected error occurred" }, status: :internal_server_error
  end

  private

    def set_transaction
      load_accessible_transaction(params[:transaction_id])
    end

    def set_attachment
      @attachment = @transaction.attachments.find_by(id: params[:id]) if valid_uuid?(params[:id])
      return if @attachment

      render json: { error: "not_found", message: "Attachment not found" }, status: :not_found
    end

    def ensure_write_scope
      authorize_scope!(:write)
    end

    def account_permission
      @entry.account.permission_for(current_resource_owner)
    end

    def render_forbidden
      render json: { error: "forbidden", message: "You do not have permission to change this transaction's attachments" }, status: :forbidden
    end

    def attachment_files
      Array(params[:attachments]).select { |file| file.is_a?(ActionDispatch::Http::UploadedFile) }
    end
end
