module Api
  class ChildrenCommunicationsController < ApplicationController
    def index
      child = Child.find(params[:id])
      attachments = child.attachments.recent_first.limit(50)

      render json: attachments.map { |attachment| AttachmentSerializer.new(attachment).as_json }
    end
  end
end
