class ArtifactSerializer
  def initialize(artifact)
    @artifact = artifact
  end

  def as_json(*)
    {
      id: @artifact.id,
      source_type: @artifact.source_type,
      content_type: @artifact.content_type,
      title: @artifact.display_title,
      subject: @artifact.subject,
      occurred_at: @artifact.occurred_at,
      captured_at: @artifact.captured_at,
      processing_state: @artifact.processing_state,
      ai_status: @artifact.ai_status,
      effective_category: @artifact.effective_category,
      tags: @artifact.tags,
      summary: @artifact.extracted_payload.to_h["summary"],
      file_count: @artifact.file_count,
      mime_types: @artifact.mime_types,
      total_byte_size: @artifact.total_byte_size,
      files: @artifact.file_metadata,
      raw_email_attached: @artifact.raw_email.attached?
    }
  end
end
