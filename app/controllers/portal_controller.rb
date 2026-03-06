class PortalController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to root_path if current_user.admin_role?
    redirect_to parent_root_path if current_user.parent_role? && current_parent_record.present?
  end
end
