class OpenAIClient
  API_BASE_URL = "https://api.openai.com".freeze

  def initialize(
    api_key: ENV["OPENAI_API_KEY"],
    model: ENV.fetch("OPENAI_MODEL", "gpt-4.1-mini"),
    project: ENV["OPENAI_PROJECT"],
    organization: ENV["OPENAI_ORG"]
  )
    @api_key = api_key
    @model = model
    @project = project
    @organization = organization
  end

  def chat_json(system:, user:, json_schema:, temperature: 0.2)
    raise "Missing OPENAI_API_KEY" if @api_key.blank?

    response = connection.post("/v1/chat/completions") do |req|
      req.headers["Authorization"] = "Bearer #{@api_key}"
      req.headers["Content-Type"] = "application/json"
      req.headers["OpenAI-Project"] = @project if @project.present?
      req.headers["OpenAI-Organization"] = @organization if @organization.present?
      req.body = {
        model: @model,
        temperature: temperature,
        messages: [
          { role: "system", content: system },
          { role: "user", content: user }
        ],
        response_format: {
          type: "json_schema",
          json_schema: json_schema
        }
      }
    end

    raise "OpenAI API error: #{response.status} (key_len=#{@api_key.to_s.length})" unless response.success?

    body = response.body
    content = body.dig("choices", 0, "message", "content")
    parsed_response = JSON.parse(content)

    { raw_response: body, parsed_response: parsed_response }
  end

  private

  def connection
    @connection ||= Faraday.new(url: API_BASE_URL) do |faraday|
      faraday.request :json
      faraday.response :json
    end
  end
end
