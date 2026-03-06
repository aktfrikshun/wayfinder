module AI
  class ExtractDocumentArtifact < ExtractArtifactBase
    private

    def user_prompt
      <<~PROMPT
        #{artifact_header}

        Document Text:
        #{artifact.normalized_text}
      PROMPT
    end
  end
end
