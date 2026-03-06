class PasswordChangesController < ApplicationController
  before_action :authenticate_user!

  def edit; end

  def update
    if current_user.update(password_params.merge(must_change_password: false, temporary_password_sent_at: nil))
      bypass_sign_in(current_user)
      redirect_to after_sign_in_path_for(current_user), notice: "Password updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
