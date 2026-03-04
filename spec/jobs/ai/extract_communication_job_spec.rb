require "rails_helper"

RSpec.describe AI::ExtractCommunicationJob, type: :job do
  it "marks communication complete with extracted data" do
    communication = create(:communication)
    service = instance_double(AI::ExtractSchoolEmail)

    allow(AI::ExtractSchoolEmail).to receive(:new).with(communication: communication).and_return(service)
    allow(service).to receive(:call).and_return(
      {
        raw_response: { "id" => "abc" },
        parsed_response: { "summary" => "Student needs help in math." }
      }
    )

    described_class.perform_now(communication.id)

    communication.reload
    expect(communication.ai_status).to eq("complete")
    expect(communication.ai_extracted).to include("summary" => "Student needs help in math.")
  end
end
