module ParentPortal
  class CommunicationsController < BaseController
    before_action :set_communication, only: :show

    def index
      @query = params[:q].to_s.strip
      @child_id = params[:child_id].presence

      @communications = Communication.joins(:child)
        .includes(:child)
        .where(children: { parent_id: @parent.id })
        .order(received_at: :desc)

      @communications = @communications.where(child_id: @child_id) if @child_id.present?
      return if @query.blank?

      @communications = @communications.where(
        "communications.subject ILIKE :q OR communications.from_email ILIKE :q OR communications.from_name ILIKE :q OR communications.ai_status ILIKE :q OR children.name ILIKE :q",
        q: "%#{@query}%"
      )
    end

    def show; end

    private

    def set_communication
      @communication = Communication.joins(:child)
        .includes(:child)
        .where(children: { parent_id: @parent.id })
        .find(params[:id])
    end
  end
end
