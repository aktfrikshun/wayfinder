module ParentPortal
  class ChildCommunicationsController < BaseController
    before_action :set_child
    before_action :set_communication, only: %i[show edit update destroy create_attachment destroy_attachment reprocess]

    def new
      @communication = @child.communications.new(
        source: "parent_portal",
        from_email: current_correspondent.email,
        from_name: current_correspondent.name,
        received_at: Time.current,
        ai_status: "pending"
      )
      @communication.correspondents << current_correspondent
    end

    def create
      @communication = @child.communications.new(communication_params)
      @communication.source ||= "parent_portal"
      @communication.received_at ||= Time.current
      @communication.ai_status ||= "pending"
      @communication.from_email ||= current_correspondent.email
      @communication.from_name ||= current_correspondent.name
      @communication.correspondents << current_correspondent unless @communication.correspondents.include?(current_correspondent)

      if @communication.save
        redirect_to edit_parent_child_communication_path(@child, @communication), notice: "Communication created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @attachments = @communication.attachments.recent_first
    end

    def edit
      @attachments = @communication.attachments.recent_first
      @new_attachment = @communication.attachments.new(
        child: @child,
        source_type: "upload",
        content_type: "unknown",
        captured_at: Time.current,
        occurred_at: Time.current,
        processing_state: "pending",
        ai_status: "pending"
      )
    end

    def update
      if @communication.update(communication_edit_params)
        redirect_to edit_parent_child_communication_path(@child, @communication), notice: "Communication updated."
      else
        @attachments = @communication.attachments.recent_first
        @new_attachment = @communication.attachments.new(child: @child)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @communication.destroy
      redirect_to edit_parent_child_path(@child), notice: "Communication deleted."
    end

    def create_attachment
      attrs = attachment_params
      files = sanitize_uploaded_files(attrs.delete(:files))

      attachment = @communication.attachments.new(attrs)
      attachment.child = @child
      attachment.source_type ||= "upload"
      attachment.captured_at ||= Time.current
      attachment.occurred_at ||= Time.current
      attachment.processing_state ||= "pending"
      attachment.ai_status ||= "pending"
      attachment.content_type = infer_content_type(files)

      if attachment.save
        attachment.files.attach(files) if files.present?
        Attachments::ProcessAttachmentJob.perform_later(attachment.id)
        redirect_to edit_parent_child_communication_path(@child, @communication), notice: "Attachment uploaded."
      else
        @communication.errors.add(:base, attachment.errors.full_messages.to_sentence)
        @attachments = @communication.attachments.recent_first
        @new_attachment = attachment
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy_attachment
      attachment = @communication.attachments.find(params[:attachment_id])
      attachment.destroy
      redirect_to edit_parent_child_communication_path(@child, @communication), notice: "Attachment removed."
    end

    def reprocess
      AI::ExtractCommunicationJob.perform_later(@communication.id)
      @communication.attachments.find_each do |attachment|
        Attachments::ProcessAttachmentJob.perform_later(attachment.id)
      end

      redirect_back fallback_location: parent_child_communication_path(@child, @communication), notice: "Reprocessing queued."
    end

    private

    def set_child
      @child = @parent.children.find(params[:child_id])
    end

    def set_communication
      @communication = @child.communications
        .joins(:correspondents)
        .where(correspondents: { id: current_correspondent.id })
        .distinct
        .find(params[:id] || params[:communication_id])
    end

    def communication_params
      params.require(:communication).permit(
        :description,
        :subject,
        :body_text,
        :body_html,
        :received_at,
        :source,
        :from_email,
        :from_name,
        correspondent_ids: []
      )
    end

    def communication_edit_params
      params.require(:communication).permit(:description)
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
        :title,
        :description,
        :subject,
        :body_text,
        :body_html,
        :source,
        :source_type,
        :captured_at,
        :occurred_at,
        files: []
      )
    end

    def sanitize_uploaded_files(files)
      Array(files).select { |file| file.respond_to?(:content_type) && file.respond_to?(:original_filename) }
    end

    def infer_content_type(files)
      file = Array(files).first
      mime = file&.content_type.to_s
      return "unknown" if mime.blank?
      return "image" if mime.start_with?("image/")
      return "pdf" if mime == "application/pdf"
      return "document" if mime.start_with?("text/") || mime.include?("word") || mime.include?("officedocument")

      "unknown"
    end
  end
end
