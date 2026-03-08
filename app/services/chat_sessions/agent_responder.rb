module ChatSessions
  class AgentResponder
    JSON_SCHEMA = {
      name: "child_growth_chat_response",
      schema: {
        type: "object",
        additionalProperties: false,
        required: %w[answer suggested_title],
        properties: {
          answer: { type: "string" },
          suggested_title: { type: "string" }
        }
      }
    }.freeze

    GENERIC_WARNING = "AI responses can be wrong. Please verify important guidance with trusted professionals.".freeze

    def self.call(child:, communication:, question:, client: OpenAIClient.new)
      new(child: child, communication: communication, question: question, client: client).call
    end

    def initialize(child:, communication:, question:, client: OpenAIClient.new)
      @child = child
      @communication = communication
      @question = question.to_s.strip
      @client = client
    end

    def call
      result = @client.chat_json(
        system: system_prompt,
        user: user_prompt,
        json_schema: JSON_SCHEMA
      )

      {
        answer: result.dig(:parsed_response, "answer").to_s,
        suggested_title: result.dig(:parsed_response, "suggested_title").to_s,
        references: reference_links,
        warning: generic_question? ? GENERIC_WARNING : nil
      }
    rescue StandardError
      {
        answer: "I had trouble generating a response. Please try again in a moment.",
        suggested_title: fallback_title,
        references: reference_links,
        warning: generic_question? ? GENERIC_WARNING : nil
      }
    end

    private

    attr_reader :child, :communication, :question

    def system_prompt
      <<~PROMPT
        You are a child growth support assistant for families and educators.
        Prioritize context from this child's communication history, attachments, and insights.
        Respond in supportive plain language with actionable next steps.
        If a question is generic child-development guidance, provide practical educational guidance and avoid medical diagnosis.
      PROMPT
    end

    def user_prompt
      <<~PROMPT
        Child Profile:
        - Name: #{child.name}
        - Nickname: #{child.nickname}
        - Grade: #{child.grade}
        - School: #{child.school_name}

        Recent Context:
        #{recent_context}

        Chat History:
        #{chat_history}

        Parent Question:
        #{question}
      PROMPT
    end

    def recent_context
      insights = child.insights.order(updated_at: :desc).limit(5)
      communications = child.communications.where.not(id: communication.id).order(received_at: :desc).limit(5)
      attachments = child.attachments.recent_first.limit(5)

      parts = []
      parts << "Insights: " + insights.map { |i| "#{i.title}: #{i.body}" }.join(" | ")
      parts << "Communications: " + communications.map { |c| "#{c.display_title}: #{c.description.presence || c.body_text.to_s.truncate(180)}" }.join(" | ")
      parts << "Attachments: " + attachments.map { |a| "#{a.display_title}: #{a.extracted_payload.to_h['summary'] || a.description || a.normalized_text.to_s.truncate(120)}" }.join(" | ")
      parts.reject(&:blank?).join("\n")
    end

    def chat_history
      communication.chat_messages.last(12).map do |msg|
        role = msg["role"].to_s
        content = msg["content"].to_s
        "#{role.upcase}: #{content}"
      end.join("\n")
    end

    def generic_question?
      lowered = question.downcase
      generic_terms = %w[normal milestone behavior sleep anxiety depression development discipline motivation growth]
      child_terms = [child.name, child.nickname, "report card", "progress report"].compact.map(&:downcase)

      generic_terms.any? { |term| lowered.include?(term) } && child_terms.none? { |term| lowered.include?(term) }
    end

    def reference_links
      return [] unless generic_question?

      lowered = question.downcase
      return growth_links if lowered.include?("milestone") || lowered.include?("development")
      return mental_health_links if lowered.include?("anxiety") || lowered.include?("depression")
      return sleep_links if lowered.include?("sleep")

      growth_links
    end

    def growth_links
      [
        { "title" => "CDC Child Development", "url" => "https://www.cdc.gov/ncbddd/childdevelopment/" },
        { "title" => "HealthyChildren (AAP)", "url" => "https://www.healthychildren.org/" }
      ]
    end

    def mental_health_links
      [
        { "title" => "CDC Children's Mental Health", "url" => "https://www.cdc.gov/childrensmentalhealth/" },
        { "title" => "NIMH Children and Mental Health", "url" => "https://www.nimh.nih.gov/health/topics/child-and-adolescent-mental-health" }
      ]
    end

    def sleep_links
      [
        { "title" => "CDC Sleep in Children", "url" => "https://www.cdc.gov/sleep/about_sleep/children.html" },
        { "title" => "HealthyChildren Sleep Guidance", "url" => "https://www.healthychildren.org/English/healthy-living/sleep/" }
      ]
    end

    def fallback_title
      question.split(/\s+/).first(8).join(" ").presence || "Child Growth Chat"
    end
  end
end
