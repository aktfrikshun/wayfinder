require "rails_helper"

RSpec.describe Artifacts::ProcessArtifactJob, type: :job do
  it "processes artifact and stores extracted payload" do
    artifact = create(:artifact, extracted_payload: {})

    allow(Artifacts::DetectShape).to receive(:call).and_call_original
    allow(Artifacts::ExtractText).to receive(:call).and_call_original
    allow(Artifacts::Classify).to receive(:call).and_call_original
    allow(AI::ExtractArtifact).to receive(:call).with(artifact).and_return(
      raw_response: { "id" => "abc" },
      parsed_response: { "summary" => "Student needs support", "signals" => ["homework"] }
    )

    described_class.perform_now(artifact.id)

    artifact.reload
    expect(artifact.processing_state).to eq("processed")
    expect(artifact.ai_status).to eq("complete")
    expect(artifact.extracted_payload).to include("summary" => "Student needs support")
  end

  it "persists failure state" do
    artifact = create(:artifact)
    allow(Artifacts::DetectShape).to receive(:call).and_raise(StandardError, "boom")

    expect { described_class.perform_now(artifact.id) }.to raise_error(StandardError, "boom")

    artifact.reload
    expect(artifact.processing_state).to eq("failed")
    expect(artifact.ai_status).to eq("failed")
    expect(artifact.ai_error).to eq("boom")
  end
end
