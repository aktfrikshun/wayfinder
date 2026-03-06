module AI
  class ExtractArtifactBase
    JSON_SCHEMA = {
      name: "artifact_extraction",
      schema: {
        type: "object",
        additionalProperties: false,
        required: %w[summary subject_area signals metrics assignments recommended_next_steps category_rationale],
        properties: {
          summary: { type: "string" },
          subject_area: { type: ["string", "null"] },
          signals: { type: "array", items: { type: "string" } },
          metrics: { type: "array", items: { type: "string" } },
          assignments: { type: "array", items: { type: "string" } },
          recommended_next_steps: { type: "array", items: { type: "string" } },
          category_rationale: { type: ["string", "null"] }
        }
      }
    }.freeze

    def initialize(artifact:, client: OpenAIClient.new)
      @artifact = artifact
      @client = client
    end

    def call
      @client.chat_json(
        system: system_prompt,
        user: user_prompt,
        json_schema: JSON_SCHEMA
      )
    end

    private

    attr_reader :artifact

    def system_prompt
      "You extract structured artifact information for family education support. Respond only with valid JSON."
    end

    def artifact_header
      <<~HEADER
        Source Type: #{artifact.source_type}
        Content Type: #{artifact.content_type}
        Subject: #{artifact.subject}
        Title: #{artifact.title}
        Category: #{artifact.effective_category}
      HEADER
    end
  end
end
