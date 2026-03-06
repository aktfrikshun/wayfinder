class ImpersonationsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_impersonation!

  def destroy
    admin = impersonator_user
    session.delete(:admin_impersonator_id)

    unless admin&.admin_role?
      sign_out current_user
      redirect_to new_user_session_path, alert: "Impersonation session expired."
      return
    end

    sign_in(:user, admin)
    redirect_to users_path, notice: "Stopped impersonating."
  end
end
