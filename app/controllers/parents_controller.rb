class ParentsController < ApplicationController
  before_action :require_admin!
  before_action :set_parent, only: %i[show edit update destroy]

  def index
    @query = params[:q].to_s.strip
    @parents = Parent.order(created_at: :desc)
    @parents = @parents.where("name ILIKE :q OR email ILIKE :q", q: "%#{@query}%") if @query.present?
  end

  def show; end

  def new
    @parent = Parent.new
  end

  def edit; end

  def create
    @parent = Parent.new(parent_params)

    if @parent.save
      redirect_to @parent, notice: "Parent created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @parent.update(parent_params)
      redirect_to @parent, notice: "Parent updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @parent.destroy
    redirect_to parents_path, notice: "Parent deleted."
  end

  private

  def set_parent
    @parent = Parent.find(params[:id])
  end

  def parent_params
    params.require(:parent).permit(:name, :email)
  end
end
