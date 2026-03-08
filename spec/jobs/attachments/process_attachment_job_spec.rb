require "rails_helper"

RSpec.describe Attachments::ProcessAttachmentJob, type: :job do
  it "processes attachment and stores extracted payload" do
    attachment = create(:attachment, extracted_payload: {})

    allow(Attachments::DetectShape).to receive(:call).and_call_original
    allow(Attachments::ExtractText).to receive(:call).and_call_original
    allow(Attachments::ExtractTables).to receive(:call).with(attachment).and_return(
      { "detected" => true, "header" => ["course", "q1"], "rows" => [{ "course" => "Math", "q1" => "97" }], "row_count" => 1 }
    )
    allow(Attachments::Classify).to receive(:call).and_call_original
    allow(AI::ExtractAttachment).to receive(:call).with(attachment).and_return(
      raw_response: { "id" => "abc" },
      parsed_response: { "summary" => "Student needs support", "signals" => ["homework"] }
    )

    described_class.perform_now(attachment.id)

    attachment.reload
    expect(attachment.processing_state).to eq("processed")
    expect(attachment.ai_status).to eq("complete")
    expect(attachment.extracted_payload).to include("summary" => "Student needs support")
    expect(attachment.extracted_payload["tabular_data"]).to be_present
    expect(attachment.metadata["tabular_data"]).to be_present
  end

  it "persists failure state" do
    attachment = create(:attachment)
    allow(Attachments::DetectShape).to receive(:call).and_raise(StandardError, "boom")

    expect { described_class.perform_now(attachment.id) }.to raise_error(StandardError, "boom")

    attachment.reload
    expect(attachment.processing_state).to eq("failed")
    expect(attachment.ai_status).to eq("failed")
    expect(attachment.ai_error).to eq("boom")
  end
end
