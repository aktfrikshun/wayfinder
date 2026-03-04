class CommunicationSerializer
  def initialize(communication)
    @communication = communication
  end

  def as_json(*)
    {
      id: @communication.id,
      subject: @communication.subject,
      received_at: @communication.received_at,
      ai_status: @communication.ai_status,
      ai_extracted: {
        summary: @communication.ai_extracted&.dig("summary")
      }
    }
  end
end
