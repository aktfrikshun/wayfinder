class ArtifactsController < ApplicationController
  before_action :require_admin!
  before_action :set_artifact, only: %i[show edit update destroy]

  def index
    @query = params[:q].to_s.strip
    @artifacts = Artifact.includes(communication: { child: :parent }).recent_first

    return if @query.blank?

    @artifacts = @artifacts.joins(communication: { child: :parent }).where(
      "artifacts.title ILIKE :q OR artifacts.subject ILIKE :q OR artifacts.source_type ILIKE :q OR " \
      "artifacts.content_type ILIKE :q OR artifacts.system_category ILIKE :q OR artifacts.ai_status ILIKE :q OR " \
      "children.name ILIKE :q OR parents.email ILIKE :q",
      q: "%#{@query}%"
    )
  end

  def show; end

  def new
    @artifact = Artifact.new(
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
    attrs = prepared_artifact_params
    return render(:new, status: :unprocessable_entity) unless attrs

    @artifact = Artifact.new(attrs)

    if @artifact.save
      redirect_to @artifact, notice: "Artifact created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    attrs = prepared_artifact_params
    return render(:edit, status: :unprocessable_entity) unless attrs

    if @artifact.update(attrs)
      redirect_to @artifact, notice: "Artifact updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @artifact.destroy
    redirect_to artifacts_path, notice: "Artifact deleted."
  end

  private

  def set_artifact
    @artifact = Artifact.find(params[:id])
  end

  def artifact_params
    params.require(:artifact).permit(
      :communication_id,
      :source_type,
      :content_type,
      :title,
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
      :raw_payload,
      :metadata,
      :tags,
      :extracted_payload,
      :ai_raw_response
    )
  end

  def prepared_artifact_params
    attrs = artifact_params.to_h

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
    @artifact ||= params[:id] ? Artifact.find(params[:id]) : Artifact.new
    @artifact.assign_attributes(artifact_params)
    @artifact.errors.add(:base, "Invalid JSON input: #{e.message}")
    nil
  end
end
