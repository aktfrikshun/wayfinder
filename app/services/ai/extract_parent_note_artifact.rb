module AI
  class ExtractParentNoteArtifact < ExtractArtifactBase
    private

    def user_prompt
      <<~PROMPT
        #{artifact_header}

        Parent Note:
        #{artifact.normalized_text}
      PROMPT
    end
  end
end
