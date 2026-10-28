# frozen_string_literal: true

class Api::V1::ImportsController < Api::V1::BaseController
  include Pagy::Backend

  # Ensure proper scope authorization
  before_action :ensure_read_scope, only: [ :index, :show, :rows, :preflight ]
  before_action :ensure_write_scope, only: [ :create, :publish ]
  before_action :reject_guest_family_config_import!, only: [ :create ]
  before_action :set_import_with_rows, only: [ :show, :publish ]
  before_action :set_import, only: [ :rows ]

  def index
    family = current_resource_owner.family
    imports_query = family.imports.ordered

    # Apply filters
    if params[:status].present?
      imports_query = imports_query.where(status: params[:status])
    end

    if params[:type].present?
      imports_query = imports_query.where(type: params[:type])
    end

    # Pagination
    @pagy, @imports = pagy(
      imports_query,
      page: safe_page_param,
      limit: safe_per_page_param
    )

    @per_page = safe_per_page_param

    render :index

  rescue StandardError => e
    Rails.logger.error "ImportsController#index error: #{e.message}"
    render json: { error: "internal_server_error", message: "An unexpected error occurred." }, status: :internal_server_error
  end

  def show
    render :show
  rescue StandardError => e
    Rails.logger.error "ImportsController#show error: #{e.message}"
    render json: { error: "internal_server_error", message: "An unexpected error occurred." }, status: :internal_server_error
  end

  def rows
    @per_page = safe_per_page_param
    @pagy, @rows = pagy(
      @import.rows_ordered,
      page: safe_page_param,
      limit: @per_page
    )
    @rows.each(&:valid?)
    @row_mapping_lookup = @import.mappings.includes(:mappable).index_by { |mapping| [ mapping.type, mapping.key.to_s ] }

    render :rows
  rescue StandardError => e
    Rails.logger.error "ImportsController#rows error: #{e.message}"
    render json: { error: "internal_server_error", message: "An unexpected error occurred." }, status: :internal_server_error
  end

  def create
    family = current_resource_owner.family

    # 1. Determine type and validate
    type = params[:type].to_s
    type = "TransactionImport" unless Import::TYPES.include?(type)
    return create_sure_import(family) if type == "SureImport"
    return create_pdf_import(family) if type == "PdfImport" || pdf_upload?

    # 2. Build the import object with permitted config attributes
    @import = family.imports.build(import_config_params.merge(type: type))
    @import.account_id = params[:account_id] if params[:account_id].present?

    # 3. Attach the uploaded file if present (with validation)
    if params[:file].present?
      file = params[:file]

      if file.size > Import.max_csv_size
        return render json: {
          error: "file_too_large",
          message: "File is too large. Maximum size is #{Import.max_csv_size / 1.megabyte}MB."
        }, status: :unprocessable_entity
      end

      unless Import::ALLOWED_CSV_MIME_TYPES.include?(file.content_type)
        return render json: {
          error: "invalid_file_type",
          message: "Invalid file type. Please upload a CSV file."
        }, status: :unprocessable_entity
      end

      @import.raw_file_str = file.read
    elsif params[:raw_file_content].present?
      if params[:raw_file_content].bytesize > Import.max_csv_size
        return render json: {
          error: "content_too_large",
          message: "Content is too large. Maximum size is #{Import.max_csv_size / 1.megabyte}MB."
        }, status: :unprocessable_entity
      end

      @import.raw_file_str = params[:raw_file_content]
    end

    # 4. Save and Process
    if @import.save
      # Generate rows if file content was provided
      if @import.uploaded?
        begin
          @import.generate_rows_from_csv
          @import.reload
        rescue StandardError => e
          Rails.logger.error "Row generation failed for import #{@import.id}: #{e.message}"
        end
      end

      # If the import is configured (has rows), we can try to auto-publish or just leave it as pending
      # For API simplicity, if enough info is provided, we might want to trigger processing

      if @import.configured? && params[:publish] == "true"
        if current_resource_owner.guest? && @import.creates_categories_or_tags?
          return render_json({ error: "forbidden", message: "Guests cannot create categories or tags", import_id: @import.id }, status: :forbidden)
        end

        @import.publish_later
      end

      render :show, status: :created
    else
      render json: {
        error: "validation_failed",
        message: "Import could not be created",
        errors: @import.errors.full_messages
      }, status: :unprocessable_entity
    end

  rescue StandardError => e
    Rails.logger.error "ImportsController#create error: #{e.message}"
    render json: { error: "internal_server_error", message: "An unexpected error occurred." }, status: :internal_server_error
  end

  # Mirrors the web ImportsController#publish permission checks.
  def publish
    unless @import.account_statement.blank? || @import.account_statement.manageable_by?(current_resource_owner)
      return render_import_forbidden
    end
    return render_import_forbidden unless @import.accounts_writable_by?(current_resource_owner)
    return if Import::FAMILY_CONFIG_TYPES.include?(@import.type) && !reject_guest_writes!

    if current_resource_owner.guest? && @import.creates_categories_or_tags?
      return render_json({ error: "forbidden", message: "Guests cannot create categories or tags" }, status: :forbidden)
    end

    unless @import.publishable?
      return render json: {
        error: "not_publishable",
        message: "Import is not ready to publish. It needs an account and reviewed, valid rows."
      }, status: :unprocessable_entity
    end

    @import.publish_later
    render :show, status: :accepted
  rescue Import::MaxRowCountExceededError
    render json: {
      error: "max_row_count_exceeded",
      message: "Import has more than #{@import.max_row_count} rows and cannot be published."
    }, status: :unprocessable_entity
  end

  def preflight
    preflight_result = Import::Preflight.new(family: current_resource_owner.family, params: preflight_params).call
    render json: preflight_result.payload, status: preflight_result.status
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: "record_not_found",
      message: "The requested resource was not found"
    }, status: :not_found
  rescue CSV::MalformedCSVError => e
    render json: {
      error: "invalid_csv",
      message: "CSV content could not be parsed",
      errors: [ e.message ]
    }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error "ImportsController#preflight error: #{e.message}"
    e.backtrace&.each { |line| Rails.logger.error line }

    render json: {
      error: "internal_server_error",
      message: "Import preflight could not be completed."
    }, status: :internal_server_error
  end

  private

    def reject_guest_family_config_import!
      return true unless Import::FAMILY_CONFIG_TYPES.include?(params[:type].to_s)

      reject_guest_writes!
    end

    def set_import
      @import = import_scope.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_import_not_found
    end

    def set_import_with_rows
      @import = import_scope.includes(:rows).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_import_not_found
    end

    def import_scope
      current_resource_owner.family.imports
    end

    def render_import_forbidden
      render json: { error: "forbidden", message: "You do not have permission to publish this import" }, status: :forbidden
    end

    def pdf_upload?
      params[:file].respond_to?(:content_type) && Import::ALLOWED_PDF_MIME_TYPES.include?(params[:file].content_type)
    end

    # Mirrors the web ImportsController#create_pdf_import: the statement is
    # stored, linked to the account, and AI extraction runs in the background.
    def create_pdf_import(family)
      user = current_resource_owner
      return render_import_forbidden_for_statements unless AccountStatement.statement_manager?(user)
      return render_pdf_ai_unavailable unless family.ai_allowed?

      file = params[:file]
      return render_validation_error("file is required") unless file.respond_to?(:read)

      if file.size > Import::MAX_PDF_SIZE
        return render json: {
          error: "file_too_large",
          message: "File is too large. Maximum size is #{Import::MAX_PDF_SIZE / 1.megabyte}MB."
        }, status: :unprocessable_entity
      end

      return render_invalid_pdf unless valid_pdf_file?(file)

      account = nil
      if params[:account_id].present?
        account = family.accounts.writable_by(user).find_by(id: params[:account_id]) if valid_uuid?(params[:account_id].to_s)
        return render_validation_error("account_id must be an account you can write to") unless account
      end

      @import = PdfImport.create_from_upload!(family: family, file: file, user: user)

      if account && !@import.assign_account!(account)
        return render json: {
          error: "account_locked",
          message: "This statement was already imported; its account cannot be changed.",
          import_id: @import.id
        }, status: :unprocessable_entity
      end

      @import.process_with_ai_later
      @import.reload
      render :show, status: :accepted
    rescue AccountStatement::DuplicateUploadError
      render json: {
        error: "duplicate_upload",
        message: "This statement was already uploaded by someone else in your family."
      }, status: :unprocessable_entity
    rescue AccountStatement::InvalidUploadError
      render_invalid_pdf
    end

    def render_import_forbidden_for_statements
      render json: { error: "forbidden", message: "You do not have permission to import statements" }, status: :forbidden
    end

    def render_pdf_ai_unavailable
      render json: { error: "ai_unavailable", message: I18n.t("imports.create.pdf_ai_unavailable") }, status: :unprocessable_entity
    end

    def render_invalid_pdf
      render json: { error: "invalid_file_type", message: "Invalid file. Please upload a PDF statement." }, status: :unprocessable_entity
    end

    def valid_pdf_file?(file)
      header = file.read(5)
      file.rewind
      header&.start_with?("%PDF-")
    end

    def render_import_not_found
      render json: { error: "not_found", message: "Import not found" }, status: :not_found
    end

    def ensure_read_scope
      authorize_scope!(:read)
    end

    def ensure_write_scope
      authorize_scope!(:write)
    end

    def import_config_params
      params.permit(
        :date_col_label,
        :amount_col_label,
        :name_col_label,
        :category_col_label,
        :tags_col_label,
        :notes_col_label,
        :account_col_label,
        :qty_col_label,
        :ticker_col_label,
        :price_col_label,
        :entity_type_col_label,
        :currency_col_label,
        :exchange_operating_mic_col_label,
        :date_format,
        :number_format,
        :signage_convention,
        :col_sep,
        :amount_type_strategy,
        :amount_type_inflow_value,
        :rows_to_skip
      )
    end

    def preflight_params
      params.permit(*Import::Preflight::PARAM_KEYS)
    end

    def create_sure_import(family)
      content, filename, content_type = sure_import_upload_attributes
      return unless content

      begin
        @import = persist_sure_import!(family, content, filename, content_type)
      rescue ActiveRecord::RecordInvalid => e
        render json: {
          error: "validation_failed",
          message: "Import could not be created",
          errors: e.record&.errors&.full_messages || @import&.errors&.full_messages || []
        }, status: :unprocessable_entity
        return
      rescue StandardError => e
        Rails.logger.error "Sure import creation failed: #{e.message}"
        render json: {
          error: "internal_server_error",
          message: "Import could not be created"
        }, status: :internal_server_error
        return
      end

      begin
        @import.publish_later if params[:publish] == "true"
      rescue Import::MaxRowCountExceededError
        render json: {
          error: "max_row_count_exceeded",
          message: "Import was uploaded but has too many rows to publish automatically.",
          import_id: @import.id
        }, status: :unprocessable_entity
        return
      rescue SureImport::PreflightError
        render json: {
          error: "preflight_failed",
          message: "Import was uploaded but did not pass Sure NDJSON preflight.",
          errors: sure_import_error_lines,
          import_id: @import.id
        }, status: :unprocessable_entity
        return
      rescue SureImport::NotPublishableError => e
        Rails.logger.warn "Sure import not publishable for import #{@import.id}: #{e.message}"
        render json: {
          error: "not_publishable",
          message: "Import was uploaded but has no publishable records.",
          import_id: @import.id
        }, status: :unprocessable_entity
        return
      rescue StandardError => e
        Rails.logger.error "Sure import publish failed for import #{@import.id}: #{e.message}"
        restore_pending_sure_import_after_publish_failure
        render json: {
          error: "publish_failed",
          message: "Import was uploaded but could not be queued for processing.",
          import_id: @import.id
        }, status: :internal_server_error
        return
      end

      render :show, status: :created
    end

    def persist_sure_import!(family, content, filename, content_type)
      import = nil
      import = family.imports.create!(type: "SureImport")
      import.ndjson_file.attach(
        io: StringIO.new(content),
        filename: filename,
        content_type: content_type
      )
      import.sync_ndjson_rows_count!
      import
    rescue StandardError => e
      clean_up_failed_sure_import(import)
      raise
    end

    def restore_pending_sure_import_after_publish_failure
      # Import#publish_later flips status to importing before enqueueing the job.
      @import.update_column(:status, "pending") if @import&.persisted? && @import.importing?
    end

    def sure_import_error_lines = @import.error.to_s.lines.map(&:strip).reject(&:blank?)

    def clean_up_failed_sure_import(import)
      return unless import

      begin
        import.ndjson_file.purge if import.ndjson_file.attached?
      rescue StandardError => e
        Rails.logger.warn "Failed to purge Sure import attachment #{import.id}: #{e.message}"
      ensure
        import.destroy if import.persisted?
      end
    end

    def sure_import_upload_attributes
      if params[:file].present?
        sure_import_file_upload_attributes(params[:file])
      elsif params[:raw_file_content].present?
        sure_import_raw_content_attributes(params[:raw_file_content].to_s)
      else
        render json: {
          error: "missing_content",
          message: "Provide a Sure NDJSON file or raw_file_content."
        }, status: :unprocessable_entity
        nil
      end
    end

    def sure_import_file_upload_attributes(file)
      if file.size > SureImport.max_ndjson_size
        render json: {
          error: "file_too_large",
          message: "File is too large. Maximum size is #{SureImport.max_ndjson_size / 1.megabyte}MB."
        }, status: :unprocessable_entity
        return
      end

      extension = File.extname(file.original_filename.to_s).downcase
      unless SureImport::ALLOWED_NDJSON_CONTENT_TYPES.include?(file.content_type) || extension.in?(%w[.ndjson .json])
        render json: {
          error: "invalid_file_type",
          message: "Invalid file type. Please upload a Sure NDJSON file."
        }, status: :unprocessable_entity
        return
      end

      content = file.read
      sure_import_validated_attributes(
        content: content,
        filename: file.original_filename.presence || "sure-import.ndjson",
        content_type: file.content_type.presence || "application/x-ndjson"
      )
    end

    def sure_import_raw_content_attributes(content)
      if content.bytesize > SureImport.max_ndjson_size
        render json: {
          error: "content_too_large",
          message: "Content is too large. Maximum size is #{SureImport.max_ndjson_size / 1.megabyte}MB."
        }, status: :unprocessable_entity
        return
      end

      sure_import_validated_attributes(
        content: content,
        filename: "sure-import.ndjson",
        content_type: "application/x-ndjson"
      )
    end

    def sure_import_validated_attributes(content:, filename:, content_type:)
      unless SureImport.valid_ndjson_first_line?(content)
        render json: {
          error: "invalid_ndjson",
          message: "Invalid Sure NDJSON content."
        }, status: :unprocessable_entity
        return
      end

      [ content, filename, content_type ]
    end

    def safe_page_param
      page = params[:page].to_i
      page > 0 ? page : 1
    end

    def safe_per_page_param
      per_page = params[:per_page].to_i
      (1..100).include?(per_page) ? per_page : 25
    end
end
