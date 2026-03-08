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
      occurred_at: Time.current
    )
  end

  def edit; end

  def create
    attrs = attachment_params.to_h
    files = attrs.delete("files")
    attrs.delete("replace_files")
    @attachment = Attachment.new(attrs)

    if @attachment.save
      @attachment.attach_uploaded_files!(files) if files.present?
      redirect_to @attachment, notice: "Attachment created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    attrs = attachment_update_params.to_h
    files = attrs.delete("files")
    replace_files = ActiveModel::Type::Boolean.new.cast(attrs.delete("replace_files"))

    if @attachment.update(attrs)
      if replace_files && files.present?
        @attachment.files.purge
      end
      @attachment.attach_uploaded_files!(files) if files.present?
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
    params.require(:attachment).permit(
      :communication_id,
      :title,
      :description,
      :replace_files,
      files: []
    )
  end

  def attachment_update_params
    params.require(:attachment).permit(
      :title,
      :description,
      :replace_files,
      files: []
    )
  end
end
