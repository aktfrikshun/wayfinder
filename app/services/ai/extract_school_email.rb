module AI
  class ExtractSchoolEmail
    JSON_SCHEMA = {
      name: "school_email_extraction",
      schema: {
        type: "object",
        additionalProperties: false,
        required: %w[summary subject_area concerns assignments signals sentiment priority],
        properties: {
          summary: { type: "string" },
          subject_area: { type: "string" },
          concerns: { type: "array", items: { type: "string" } },
          assignments: {
            type: "array",
            items: {
              type: "object",
              additionalProperties: false,
              required: %w[title due_date details],
              properties: {
                title: { type: "string" },
                due_date: { type: "string" },
                details: { type: "string" }
              }
            }
          },
          signals: {
            type: "array",
            items: {
              type: "object",
              additionalProperties: false,
              required: %w[type description confidence],
              properties: {
                type: { type: "string" },
                description: { type: "string" },
                confidence: { type: "number" }
              }
            }
          },
          sentiment: { type: "string" },
          priority: { type: "string" }
        }
      }
    }.freeze

    def initialize(communication:, client: OpenAIClient.new)
      @communication = communication
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

    def system_prompt
      "You extract structured insights from school communications for parents. Preserve school year and quarter/period labels for all academic metrics. Respond only with valid JSON."
    end

    def user_prompt
      <<~PROMPT
        Subject: #{@communication.subject}
        From: #{@communication.from_name} <#{@communication.from_email}>
        Received At: #{@communication.received_at}
        Description:
        #{@communication.description}

        Text Body:
        #{@communication.body_text}

        HTML Body:
        #{@communication.body_html}

        Attachments:
        #{attachments_context}
      PROMPT
    end

    def attachments_context
      attachments = @communication.attachments.includes(files_attachments: :blob).order(:created_at)
      return "None" if attachments.blank?

      attachments.map.with_index(1) do |attachment, idx|
        file_list = attachment.files.map { |file| "#{file.filename} (#{file.blob&.content_type || "unknown"})" }
        extracted_text = attachment.normalized_text.presence || attachment.body_text.presence || "(no extracted text)"
        tabular_data = attachment.metadata.to_h["tabular_data"] || attachment.extracted_payload.to_h["tabular_data"]

        <<~BLOCK
          Attachment #{idx}:
          - Title: #{attachment.title.presence || "(untitled)"}
          - Description: #{attachment.description.presence || "(none)"}
          - Content Type: #{attachment.content_type}
          - Files: #{file_list.presence&.join(", ") || "(none)"}
          - Extracted File/Text Content:
          #{truncate_for_prompt(extracted_text)}
          - Tabular Data JSON:
          #{truncate_for_prompt(JSON.pretty_generate(compact_tabular_payload(tabular_data)), max_chars: 2_500)}
        BLOCK
      end.join("\n")
    end

    def compact_tabular_payload(tabular_data)
      return { "detected" => false } unless tabular_data.is_a?(Hash) && tabular_data["detected"] == true

      {
        "detected" => true,
        "school_year" => tabular_data["school_year"],
        "period_columns" => tabular_data["period_columns"],
        "header" => tabular_data["header"],
        "row_count" => tabular_data["row_count"],
        "rows" => Array(tabular_data["rows"]).first(30)
      }
    end

    def truncate_for_prompt(text, max_chars: 4_000)
      normalized = text.to_s.strip
      return normalized if normalized.length <= max_chars

      "#{normalized[0...max_chars]}...(truncated)"
    end
  end
end
