class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  protected

  def require_admin!
    authenticate_user!
    return if current_user&.admin_role?

    redirect_to after_sign_in_path_for(current_user), alert: "Admin access required."
  end

  def require_parent!
    authenticate_user!
    return if current_user&.parent_role?

    redirect_to after_sign_in_path_for(current_user), alert: "Parent access required."
  end

  def current_parent_record
    return nil unless current_user&.parent_role?

    @current_parent_record ||= Parent.find_or_create_by!(email: current_user.email)
  end
  helper_method :current_parent_record

  def impersonating?
    session[:admin_impersonator_id].present?
  end
  helper_method :impersonating?

  def impersonator_user
    return nil unless impersonating?

    @impersonator_user ||= User.find_by(id: session[:admin_impersonator_id])
  end
  helper_method :impersonator_user

  def require_impersonation!
    return if impersonating?

    redirect_to after_sign_in_path_for(current_user), alert: "Not currently impersonating."
  end

  def after_sign_in_path_for(resource)
    return super unless resource.is_a?(User)

    return root_path if resource.admin_role?
    return current_parent_record.present? ? parent_root_path : portal_path if resource.parent_role?

    portal_path
  end
end
