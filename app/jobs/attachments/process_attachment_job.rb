module Attachments
  class ProcessAttachmentJob < ApplicationJob
    queue_as :ai_extract

    def perform(attachment_id)
      attachment = Attachment.find(attachment_id)
      attachment.update!(ai_status: "processing", ai_error: nil)

      Attachments::DetectShape.call(attachment)
      Attachments::ExtractText.call(attachment)
      Attachments::Classify.call(attachment)

      ai_result = AI::ExtractAttachment.call(attachment)

      attachment.update!(
        processing_state: "processed",
        ai_status: "complete",
        ai_raw_response: ai_result[:raw_response],
        extracted_payload: attachment.extracted_payload.to_h.merge(ai_result[:parsed_response]),
        last_processed_at: Time.current
      )
      Insights::UpsertFromAttachment.call(attachment)
    rescue StandardError => e
      attachment&.update(processing_state: "failed", ai_status: "failed", ai_error: e.message)
      raise
    end
  end
end
