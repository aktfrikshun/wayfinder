require "rails_helper"

RSpec.describe Artifact, type: :model do
  it "validates controlled values" do
    artifact = build(:artifact, source_type: "bad", content_type: "bad", processing_state: "bad", ai_status: "bad")

    expect(artifact).not_to be_valid
    expect(artifact.errors[:source_type]).to be_present
    expect(artifact.errors[:content_type]).to be_present
    expect(artifact.errors[:processing_state]).to be_present
    expect(artifact.errors[:ai_status]).to be_present
  end

  it "prefers user category over system category for effective_category" do
    artifact = build(:artifact, system_category: "assignment", user_category: "custom")

    expect(artifact.effective_category).to eq("custom")
  end

  it "builds display title from fallbacks" do
    artifact = build(:artifact, title: nil, subject: nil, system_category: "assessment_result")

    expect(artifact.display_title).to eq("Assessment result")
  end

  it "detects ocr requirement" do
    expect(build(:artifact, content_type: "image").needs_ocr?).to eq(true)
    expect(build(:artifact, content_type: "pdf", metadata: { "needs_ocr" => true }).needs_ocr?).to eq(true)
    expect(build(:artifact, content_type: "message").needs_ocr?).to eq(false)
  end
end
