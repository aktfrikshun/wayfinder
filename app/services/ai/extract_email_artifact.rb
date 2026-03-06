module AI
  class ExtractEmailArtifact < ExtractArtifactBase
    private

    def user_prompt
      <<~PROMPT
        #{artifact_header}

        Email Body:
        #{artifact.normalized_text}
      PROMPT
    end
  end
end
