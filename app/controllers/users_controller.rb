class UsersController < ApplicationController
  before_action :require_admin!
  before_action :set_user, only: %i[show edit update destroy]

  def index
    @query = params[:q].to_s.strip
    @users = User.order(created_at: :desc)
    return if @query.blank?

    pattern = "%#{@query}%"
    @users = @users.where("email ILIKE :q OR role ILIKE :q", q: pattern)
  end

  def show; end

  def new
    @user = User.new
  end

  def edit; end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to @user, notice: "User created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(update_user_params)
      redirect_to @user, notice: "User updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to users_path, alert: "You cannot delete your own account."
      return
    end

    @user.destroy
    redirect_to users_path, notice: "User deleted."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :role, :password, :password_confirmation)
  end

  def update_user_params
    attrs = user_params
    return attrs if attrs[:password].present? || attrs[:password_confirmation].present?

    attrs.except(:password, :password_confirmation)
  end
end
