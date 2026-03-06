module ParentPortal
  class DashboardController < BaseController
    def index
      @children = @parent.children.order(:name)
      @communications_count = Communication.joins(:child).where(children: { parent_id: @parent.id }).count
      @recent_communications = Communication.joins(:child)
        .includes(:child)
        .where(children: { parent_id: @parent.id })
        .order(received_at: :desc)
        .limit(10)
    end
  end
end
