module Profiles
  class CorrespondentsController < ApplicationController
    before_action :authenticate_user!

    def edit
      @correspondent = ensure_correspondent!
    end

    def update
      @correspondent = ensure_correspondent!

      if @correspondent.update(correspondent_params)
        redirect_to edit_profile_correspondent_path, notice: "Profile settings updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def ensure_correspondent!
      current_user.correspondent || current_user.create_correspondent!(
        email: current_user.email,
        name: current_user.email
      )
    end

    def correspondent_params
      params.require(:correspondent).permit(:name, :email, :phone)
    end
  end
end
