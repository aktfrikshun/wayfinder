module AI
  class ExtractCommunicationJob < ApplicationJob
    queue_as :ai_extract

    def perform(communication_id)
      communication = Communication.find(communication_id)
      communication.update!(ai_status: "processing", ai_error: nil)

      result = AI::ExtractSchoolEmail.new(communication: communication).call

      communication.update!(
        ai_status: "complete",
        ai_raw_response: result[:raw_response],
        ai_extracted: result[:parsed_response]
      )
    rescue StandardError => e
      communication&.update(ai_status: "failed", ai_error: e.message)
      raise
    end
  end
end
