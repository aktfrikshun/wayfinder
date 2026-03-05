class ChildrenController < ApplicationController
  before_action :require_admin!
  before_action :set_child, only: %i[show edit update destroy]

  def index
    @query = params[:q].to_s.strip
    @children = Child.includes(:parent).order(created_at: :desc)

    return if @query.blank?

    @children = @children.joins(:parent).where(
      "children.name ILIKE :q OR children.grade ILIKE :q OR children.school_name ILIKE :q OR " \
      "children.inbound_alias ILIKE :q OR parents.name ILIKE :q OR parents.email ILIKE :q",
      q: "%#{@query}%"
    )
  end

  def show; end

  def new
    @child = Child.new
  end

  def edit; end

  def create
    @child = Child.new(child_params)

    if @child.save
      redirect_to @child, notice: "Child created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @child.update(child_params)
      redirect_to @child, notice: "Child updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @child.destroy
    redirect_to children_path, notice: "Child deleted."
  end

  private

  def set_child
    @child = Child.find(params[:id])
  end

  def child_params
    params.require(:child).permit(:parent_id, :name, :grade, :school_name, :inbound_alias)
  end
end
