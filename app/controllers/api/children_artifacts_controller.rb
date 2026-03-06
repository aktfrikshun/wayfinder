module Api
  class ChildrenArtifactsController < ApplicationController
    def index
      child = Child.find(params[:id])
      artifacts = child.artifacts.recent_first.limit(50)

      render json: artifacts.map { |artifact| ArtifactSerializer.new(artifact).as_json }
    end
  end
end
