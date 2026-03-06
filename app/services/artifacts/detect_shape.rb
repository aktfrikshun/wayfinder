module Artifacts
  class DetectShape
    MIME_MAP = {
      "application/pdf" => "pdf",
      "text/plain" => "document",
      "application/msword" => "document",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => "document"
    }.freeze

    def self.call(artifact)
      new(artifact).call
    end

    def initialize(artifact)
      @artifact = artifact
    end

    def call
      updates = {
        processing_state: "detecting",
        metadata: @artifact.metadata.to_h
      }

      updates[:content_type] = detect_content_type
      updates[:metadata]["detected_at"] = Time.current.iso8601
      updates[:metadata]["detection_reason"] = detection_reason(updates[:content_type])

      @artifact.update!(updates)
      @artifact
    end

    private

    def detect_content_type
      return "message" if @artifact.email? || @artifact.parent_note?

      attachments = @artifact.files.attachments
      return @artifact.content_type if attachments.empty?

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
