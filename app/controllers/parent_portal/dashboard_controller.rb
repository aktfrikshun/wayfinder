module ParentPortal
  class DashboardController < BaseController
    def index
      @children = @parent.children.order(:name)
      @artifacts_count = Artifact.joins(:child).where(children: { parent_id: @parent.id }).count
      @recent_artifacts = Artifact.joins(:child)
        .includes(:child)
        .where(children: { parent_id: @parent.id })
        .recent_first
        .limit(10)
    end
  end
end
