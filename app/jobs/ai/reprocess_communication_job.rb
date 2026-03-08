module AI
  class ReprocessCommunicationJob < ApplicationJob
    queue_as :ai_extract

    def perform(communication_id)
      communication = Communication.find(communication_id)

      communication.attachments.find_each do |attachment|
        Attachments::ProcessAttachmentJob.perform_now(attachment.id)
      end

      AI::ExtractCommunicationJob.perform_now(communication.id)
    end
  end
end
