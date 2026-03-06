module AI
  class ExtractImageArtifact < ExtractArtifactBase
    private

    def user_prompt
      <<~PROMPT
        #{artifact_header}

        OCR / Image Text:
        #{artifact.normalized_text}
      PROMPT
    end
  end
end
