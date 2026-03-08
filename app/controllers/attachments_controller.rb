class AttachmentsController < ApplicationController
  before_action :require_admin!
  before_action :set_attachment, only: %i[show edit update destroy]

  def index
    @query = params[:q].to_s.strip
    @communication = Communication.find_by(id: params[:communication_id]) if params[:communication_id].present?
    @attachments = Attachment.includes(communication: { child: :parent }).recent_first
    @attachments = @attachments.where(communication_id: @communication.id) if @communication.present?

    return if @query.blank?

    @attachments = @attachments.joins(communication: { child: :parent }).where(
      "attachments.title ILIKE :q OR attachments.subject ILIKE :q OR attachments.source_type ILIKE :q OR " \
      "attachments.content_type ILIKE :q OR attachments.system_category ILIKE :q OR attachments.ai_status ILIKE :q OR " \
      "children.name ILIKE :q OR parents.email ILIKE :q",
      q: "%#{@query}%"
    )
  end

  def show; end

  def new
    @attachment = Attachment.new(
      communication_id: params[:communication_id],
      captured_at: Time.current,
      occurred_at: Time.current,
      source_type: "email",
      content_type: "message",
      processing_state: "pending",
      ai_status: "pending"
    )
  end

  def edit; end

  def create
    attrs = prepared_attachment_params
    return render(:new, status: :unprocessable_entity) unless attrs

    files = attrs.delete("files")
    attrs.delete("replace_files")
    @attachment = Attachment.new(attrs)

    if @attachment.save
      @attachment.files.attach(files) if files.present?
      redirect_to @attachment, notice: "Attachment created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    attrs = prepared_attachment_params
    return render(:edit, status: :unprocessable_entity) unless attrs

    files = attrs.delete("files")
    replace_files = ActiveModel::Type::Boolean.new.cast(attrs.delete("replace_files"))

    if @attachment.update(attrs)
      if replace_files && files.present?
        @attachment.files.purge
      end
      @attachment.files.attach(files) if files.present?
      redirect_to @attachment, notice: "Attachment updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @attachment.destroy
    redirect_to attachments_path, notice: "Attachment deleted."
  end

  private

  def set_attachment
    @attachment = Attachment.find(params[:id])
  end

  def attachment_params
    raw_params = params[:attachment]
    permitted_source =
      if raw_params.is_a?(ActionController::Parameters)
        raw_params
      else
        ActionController::Parameters.new(raw_params || {})
      end

    permitted_source.permit(
      :communication_id,
      :source_type,
      :content_type,
      :title,
      :description,
      :source,
      :from_email,
      :from_name,
      :subject,
      :occurred_at,
      :captured_at,
      :body_text,
      :body_html,
      :processing_state,
      :text_extraction_method,
      :raw_extracted_text,
      :ocr_text,
      :normalized_text,
      :text_quality_score,
      :system_category,
      :user_category,
      :category_confidence,
      :ai_status,
      :ai_error,
      :replace_files,
      :raw_payload,
      :metadata,
      :tags,
      :extracted_payload,
      :ai_raw_response,
      files: []
    )
  end

  def prepared_attachment_params
    attrs = attachment_params.to_h

    %w[raw_payload metadata tags extracted_payload ai_raw_response].each do |field|
      raw_value = attrs[field]
      next unless raw_value.is_a?(String)

      compact = raw_value.strip
      attrs[field] =
        if compact.blank?
          field == "tags" ? [] : {}
        else
          JSON.parse(compact)
        end
    end

    attrs
  rescue JSON::ParserError => e
    @attachment ||= params[:id] ? Attachment.find(params[:id]) : Attachment.new
    @attachment.assign_attributes(attachment_params)
    @attachment.errors.add(:base, "Invalid JSON input: #{e.message}")
    nil
  end
end
