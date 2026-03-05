module Api
  class ChildrenCommunicationsController < ApplicationController
    def index
      child = Child.find(params[:id])
      communications = child.communications.order(received_at: :desc).limit(50)

      render json: communications.map { |communication| CommunicationSerializer.new(communication).as_json }
    end
  end
end
