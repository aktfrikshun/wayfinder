module AI
  class ExtractEmailAttachment < ExtractAttachmentBase
    private

    def user_prompt
      <<~PROMPT
        #{attachment_header}

        Email Body:
        #{attachment.normalized_text}

        #{tabular_context}
      PROMPT
    end
  end
end
