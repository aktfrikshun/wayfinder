class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  protected

  def require_admin!
    authenticate_user!
    return if current_user&.admin_role?

    sign_out current_user
    redirect_to new_user_session_path, alert: "Admin access required."
  end

  def after_sign_in_path_for(resource)
    return super unless resource.is_a?(User)

    return root_path if resource.admin_role?

    sign_out resource
    flash[:alert] = "Admin access required."
    new_user_session_path
  end
end
