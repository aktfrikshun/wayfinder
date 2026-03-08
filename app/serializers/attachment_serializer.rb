class AttachmentSerializer
  def initialize(attachment)
    @attachment = attachment
  end

  def as_json(*)
    {
      id: @attachment.id,
      source_type: @attachment.source_type,
      content_type: @attachment.content_type,
      title: @attachment.display_title,
      description: @attachment.description,
      subject: @attachment.subject,
      occurred_at: @attachment.occurred_at,
      captured_at: @attachment.captured_at,
      processing_state: @attachment.processing_state,
      ai_status: @attachment.ai_status,
      effective_category: @attachment.effective_category,
      tags: @attachment.tags,
      summary: @attachment.extracted_payload.to_h["summary"],
      file_count: @attachment.file_count,
      mime_types: @attachment.mime_types,
      total_byte_size: @attachment.total_byte_size,
      primary_file_type: @attachment.primary_file_type,
      files: @attachment.file_metadata,
      raw_email_attached: @attachment.raw_email.attached?
    }
  end
end
