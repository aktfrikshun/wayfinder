module AI
  class ExtractDocumentAttachment < ExtractAttachmentBase
    private

    def user_prompt
      <<~PROMPT
        #{attachment_header}

        Document Text:
        #{attachment.normalized_text}

        #{tabular_context}
      PROMPT
    end
  end
end
