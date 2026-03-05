class DashboardController < ApplicationController
  before_action :require_admin!

  def index
    @query = params[:q].to_s.strip

    @parents_count = Parent.count
    @children_count = Child.count
    @communications_count = Communication.count
    @users_count = User.count

    @recent_communications = Communication.includes(child: :parent).order(received_at: :desc).limit(8)

    return if @query.blank?

    pattern = "%#{@query}%"

    @parents_results = Parent.where("name ILIKE :q OR email ILIKE :q", q: pattern).limit(10)

    @children_results = Child.joins(:parent)
      .where(
        "children.name ILIKE :q OR children.grade ILIKE :q OR children.school_name ILIKE :q OR " \
        "children.inbound_alias ILIKE :q OR parents.name ILIKE :q OR parents.email ILIKE :q",
        q: pattern
      )
      .limit(10)

    @communications_results = Communication.joins(child: :parent)
      .where(
        "communications.subject ILIKE :q OR communications.from_email ILIKE :q OR communications.from_name ILIKE :q OR " \
        "communications.source ILIKE :q OR communications.ai_status ILIKE :q OR children.name ILIKE :q OR parents.email ILIKE :q",
        q: pattern
      )
      .order(received_at: :desc)
      .limit(10)

    @users_results = User.where("email ILIKE :q OR role ILIKE :q", q: pattern).limit(10)
  end
end
