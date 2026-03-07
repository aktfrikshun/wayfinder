module ParentPortal
  class ChildCommunicationsController < BaseController
    before_action :set_child
    before_action :set_communication, only: %i[show edit update destroy create_artifact destroy_artifact reprocess]

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
      @artifacts = @communication.artifacts.recent_first
    end

    def edit
      @artifacts = @communication.artifacts.recent_first
      @new_artifact = @communication.artifacts.new(
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
      attrs = communication_params
      attrs[:correspondent_ids] = Array(attrs[:correspondent_ids]).reject(&:blank?)
      attrs[:correspondent_ids] |= [current_correspondent.id]

      if @communication.update(attrs)
        redirect_to edit_parent_child_communication_path(@child, @communication), notice: "Communication updated."
      else
        @artifacts = @communication.artifacts.recent_first
        @new_artifact = @communication.artifacts.new(child: @child)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @communication.destroy
      redirect_to edit_parent_child_path(@child), notice: "Communication deleted."
    end

    def create_artifact
      attrs = artifact_params
      files = attrs.delete(:files)

      artifact = @communication.artifacts.new(attrs)
      artifact.child = @child
      artifact.source_type ||= "upload"
      artifact.captured_at ||= Time.current
      artifact.occurred_at ||= Time.current
      artifact.processing_state ||= "pending"
      artifact.ai_status ||= "pending"
      artifact.content_type = infer_content_type(files, artifact.content_type)

      if artifact.save
        artifact.files.attach(files) if files.present?
        Artifacts::ProcessArtifactJob.perform_later(artifact.id)
        redirect_to edit_parent_child_communication_path(@child, @communication), notice: "Artifact uploaded."
      else
        @communication.errors.add(:base, artifact.errors.full_messages.to_sentence)
        @artifacts = @communication.artifacts.recent_first
        @new_artifact = artifact
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy_artifact
      artifact = @communication.artifacts.find(params[:artifact_id])
      artifact.destroy
      redirect_to edit_parent_child_communication_path(@child, @communication), notice: "Artifact removed."
    end

    def reprocess
      AI::ExtractCommunicationJob.perform_later(@communication.id)
      @communication.artifacts.find_each do |artifact|
        Artifacts::ProcessArtifactJob.perform_later(artifact.id)
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

    def artifact_params
      params.require(:artifact).permit(
        :title,
        :subject,
        :body_text,
        :body_html,
        :source,
        :source_type,
        :content_type,
        :captured_at,
        :occurred_at,
        files: []
      )
    end

    def infer_content_type(files, fallback)
      file = Array(files).first
      mime = file&.content_type.to_s
      return fallback.presence || "unknown" if mime.blank?
      return "image" if mime.start_with?("image/")
      return "pdf" if mime == "application/pdf"
      return "document" if mime.start_with?("text/") || mime.include?("word") || mime.include?("officedocument")

      fallback.presence || "unknown"
    end
  end
end
