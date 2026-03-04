require "rails_helper"

RSpec.describe AI::ExtractSchoolEmail, type: :service do
  it "returns parsed structured output" do
    communication = create(:communication, subject: "Reading update")
    client = instance_double(OpenAIClient)

    expected = {
      raw_response: { "id" => "resp_123" },
      parsed_response: {
        "summary" => "Reading progress is strong.",
        "subject_area" => "ELA",
        "concerns" => [],
        "assignments" => [],
        "signals" => [],
        "sentiment" => "positive",
        "priority" => "low"
      }
    }

    allow(client).to receive(:chat_json).and_return(expected)

    result = described_class.new(communication: communication, client: client).call

    expect(result).to eq(expected)
  end
end
