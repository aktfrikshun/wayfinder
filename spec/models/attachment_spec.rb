require "rails_helper"

RSpec.describe Attachment, type: :model do
  it "validates controlled values" do
    attachment = build(:attachment, source_type: "bad", content_type: "bad", processing_state: "bad", ai_status: "bad")

    expect(attachment).not_to be_valid
    expect(attachment.errors[:source_type]).to be_present
    expect(attachment.errors[:content_type]).to be_present
    expect(attachment.errors[:processing_state]).to be_present
    expect(attachment.errors[:ai_status]).to be_present
  end

  it "prefers user category over system category for effective_category" do
    attachment = build(:attachment, system_category: "assignment", user_category: "custom")

    expect(attachment.effective_category).to eq("custom")
  end

  it "builds display title from fallbacks" do
    attachment = build(:attachment, title: nil, subject: nil, system_category: "assessment_result")

    expect(attachment.display_title).to eq("Assessment result")
  end

  it "detects ocr requirement" do
    expect(build(:attachment, content_type: "image").needs_ocr?).to eq(true)
    expect(build(:attachment, content_type: "pdf", metadata: { "needs_ocr" => true }).needs_ocr?).to eq(true)
    expect(build(:attachment, content_type: "message").needs_ocr?).to eq(false)
  end
end
