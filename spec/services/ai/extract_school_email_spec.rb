require "rails_helper"

RSpec.describe AI::ExtractSchoolEmail, type: :service do
  it "returns parsed structured output" do
    communication = create(:communication, subject: "Reading update")
    attachment = create(
      :attachment,
      communication: communication,
      child: communication.child,
      title: "Report Card",
      description: "Q2 teacher report",
      normalized_text: "Student is improving in reading fluency."
    )
    attachment.attach_file_io!(
      io: StringIO.new("report body"),
      filename: "report.txt",
      content_type: "text/plain"
    )
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

    expect(client).to receive(:chat_json).with(
      hash_including(
        user: a_string_including(
          "Description:",
          "Attachments:",
          "Report Card",
          "Q2 teacher report",
          "Student is improving in reading fluency.",
          "report.txt (text/plain)"
        )
      )
    ).and_return(expected)

    result = described_class.new(communication: communication, client: client).call

    expect(result).to eq(expected)
  end
end
