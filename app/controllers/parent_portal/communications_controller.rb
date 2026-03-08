module ParentPortal
  class CommunicationsController < BaseController
    before_action :set_attachment, only: :show

    def index
      @query = params[:q].to_s.strip
      @child_id = params[:child_id].presence

      @attachments = Attachment.joins(:child)
        .includes(:child)
        .where(children: { parent_id: @parent.id })
        .recent_first

      @attachments = @attachments.where(child_id: @child_id) if @child_id.present?
      return if @query.blank?

      @attachments = @attachments.where(
        "attachments.subject ILIKE :q OR attachments.from_email ILIKE :q OR attachments.from_name ILIKE :q OR attachments.ai_status ILIKE :q OR children.name ILIKE :q",
        q: "%#{@query}%"
      )
    end

    def show; end

    private

    def set_attachment
      @attachment = Attachment.joins(:child)
        .includes(:child)
        .where(children: { parent_id: @parent.id })
        .find(params[:id])
    end
  end
end
