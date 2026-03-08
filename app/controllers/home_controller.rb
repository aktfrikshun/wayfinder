class HomeController < ApplicationController
  def index
    return unless user_signed_in?

    if current_user.admin_role?
      redirect_to dashboard_path
    elsif current_user.parent_role?
      redirect_to(current_parent_record.present? ? parent_root_path : portal_path)
    else
      redirect_to portal_path
    end
  end
end
