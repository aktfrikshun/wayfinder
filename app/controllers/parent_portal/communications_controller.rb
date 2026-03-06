module ParentPortal
  class CommunicationsController < BaseController
    before_action :set_artifact, only: :show

    def index
      @query = params[:q].to_s.strip
      @child_id = params[:child_id].presence

      @artifacts = Artifact.joins(:child)
        .includes(:child)
        .where(children: { parent_id: @parent.id })
        .recent_first

      @artifacts = @artifacts.where(child_id: @child_id) if @child_id.present?
      return if @query.blank?

      @artifacts = @artifacts.where(
        "artifacts.subject ILIKE :q OR artifacts.from_email ILIKE :q OR artifacts.from_name ILIKE :q OR artifacts.ai_status ILIKE :q OR children.name ILIKE :q",
        q: "%#{@query}%"
      )
    end

    def show; end

    private

    def set_artifact
      @artifact = Artifact.joins(:child)
        .includes(:child)
        .where(children: { parent_id: @parent.id })
        .find(params[:id])
    end
  end
end
