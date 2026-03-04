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
      "You extract structured insights from school communications for parents. Respond only with valid JSON."
    end

    def user_prompt
      <<~PROMPT
        Subject: #{@communication.subject}
        From: #{@communication.from_name} <#{@communication.from_email}>
        Received At: #{@communication.received_at}

        Text Body:
        #{@communication.body_text}

        HTML Body:
        #{@communication.body_html}
      PROMPT
    end
  end
end
