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
      "You extract structured attachment information for family education support. Preserve school year and quarter/period labels for all metrics. Respond only with valid JSON."
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

    def tabular_context
      table_data = attachment.metadata.to_h["tabular_data"] || attachment.extracted_payload.to_h["tabular_data"]
      return "Tabular Data: none" unless table_data.is_a?(Hash) && table_data["detected"] == true

      rows = Array(table_data["rows"]).first(40)
      payload = {
        "school_year" => table_data["school_year"],
        "period_columns" => table_data["period_columns"],
        "header" => table_data["header"],
        "row_count" => table_data["row_count"],
        "rows" => rows
      }

      "Tabular Data JSON:\n#{JSON.pretty_generate(payload)}"
    end
  end
end
