module Artifacts
  class ProcessArtifactJob < ApplicationJob
    queue_as :ai_extract

    def perform(artifact_id)
      artifact = Artifact.find(artifact_id)
      artifact.update!(ai_status: "processing", ai_error: nil)

      Artifacts::DetectShape.call(artifact)
      Artifacts::ExtractText.call(artifact)
      Artifacts::Classify.call(artifact)

      ai_result = AI::ExtractArtifact.call(artifact)

      artifact.update!(
        processing_state: "processed",
        ai_status: "complete",
        ai_raw_response: ai_result[:raw_response],
        extracted_payload: artifact.extracted_payload.to_h.merge(ai_result[:parsed_response])
      )
      Insights::UpsertFromArtifact.call(artifact)
    rescue StandardError => e
      artifact&.update(processing_state: "failed", ai_status: "failed", ai_error: e.message)
      raise
    end
  end
end
