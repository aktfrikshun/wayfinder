module ParentPortal
  class DashboardController < BaseController
    def index
      @children = @parent.children.order(:name)
      @attachments_count = Attachment.joins(:child).where(children: { parent_id: @parent.id }).count
      @recent_attachments = Attachment.joins(:child)
        .includes(:child)
        .where(children: { parent_id: @parent.id })
        .recent_first
        .limit(10)
    end
  end
end
