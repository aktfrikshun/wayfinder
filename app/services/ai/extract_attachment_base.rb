module AI
  class ExtractAttachmentBase
    JSON_SCHEMA = {
      name: "attachment_extraction",
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

    def initialize(attachment:, client: OpenAIClient.new)
      @attachment = attachment
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

    attr_reader :attachment

    def system_prompt
      "You extract structured attachment information for family education support. Respond only with valid JSON."
    end

    def attachment_header
      <<~HEADER
        Source Type: #{attachment.source_type}
        Content Type: #{attachment.content_type}
        Subject: #{attachment.subject}
        Title: #{attachment.title}
        Category: #{attachment.effective_category}
      HEADER
    end
  end
end
