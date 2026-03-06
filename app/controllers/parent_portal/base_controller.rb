module ParentPortal
  class BaseController < ApplicationController
    before_action :require_parent!
    before_action :set_parent

    private

    def set_parent
      @parent = current_parent_record
      return if @parent.present?

      redirect_to portal_path, alert: "No parent profile found for #{current_user.email}."
    end
  end
end
