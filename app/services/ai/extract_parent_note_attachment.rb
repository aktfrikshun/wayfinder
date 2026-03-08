module AI
  class ExtractParentNoteAttachment < ExtractAttachmentBase
    private

    def user_prompt
      <<~PROMPT
        #{attachment_header}

        Parent Note:
        #{attachment.normalized_text}
      PROMPT
    end
  end
end
