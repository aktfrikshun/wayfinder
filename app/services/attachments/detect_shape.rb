module Attachments
  class DetectShape
    MIME_MAP = {
      "application/pdf" => "pdf",
      "text/plain" => "document",
      "application/msword" => "document",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => "document"
    }.freeze

    def self.call(attachment)
      new(attachment).call
    end

    def initialize(attachment)
      @attachment = attachment
    end

    def call
      updates = {
        processing_state: "detecting",
        metadata: @attachment.metadata.to_h
      }

      updates[:content_type] = detect_content_type
      updates[:metadata]["detected_at"] = Time.current.iso8601
      updates[:metadata]["detection_reason"] = detection_reason(updates[:content_type])

      @attachment.update!(updates)
      @attachment
    end

    private

    def detect_content_type
      return "message" if @attachment.email? || @attachment.parent_note?

      attachments = @attachment.files.attachments
      return @attachment.content_type if attachments.empty?

      content_types = attachments.map { |attachment| attachment.blob&.content_type }.compact
      return "image" if content_types.any? { |ct| ct.start_with?("image/") }
      return "pdf" if content_types.include?("application/pdf")

      mapped = content_types.lazy.map { |ct| MIME_MAP[ct] }.find(&:present?)
      mapped || "unknown"
    end

    def detection_reason(content_type)
      case content_type
      when "message"
        "source_type"
      when "image", "pdf", "document"
        "attachment_mime"
      else
        "fallback"
      end
    end
  end
end
