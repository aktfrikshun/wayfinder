module ParentPortal
  class ChildrenController < BaseController
    before_action :set_child, only: %i[show edit update destroy]

    def index
      @query = params[:q].to_s.strip
      @children = @parent.children.order(created_at: :desc)
      return if @query.blank?

      @children = @children.where(
        "name ILIKE :q OR grade ILIKE :q OR school_name ILIKE :q OR inbound_alias ILIKE :q",
        q: "%#{@query}%"
      )
    end

    def show
      @recent_artifacts = @child.artifacts.recent_first.limit(10)
    end

    def new
      @child = @parent.children.new
    end

    def edit; end

    def create
      @child = @parent.children.new(child_params)

      if @child.save
        redirect_to parent_child_path(@child), notice: "Child created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @child.update(child_params)
        redirect_to parent_child_path(@child), notice: "Child updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @child.destroy
      redirect_to parent_children_path, notice: "Child deleted."
    end

    private

    def set_child
      @child = @parent.children.find(params[:id])
    end

    def child_params
      params.require(:child).permit(:name, :grade, :school_name, :inbound_alias)
    end
  end
end
