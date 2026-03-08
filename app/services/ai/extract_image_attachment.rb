module AI
  class ExtractImageAttachment < ExtractAttachmentBase
    private

    def user_prompt
      <<~PROMPT
        #{attachment_header}

        OCR / Image Text:
        #{attachment.normalized_text}
      PROMPT
    end
  end
end
