require "rails_helper"

RSpec.describe Attachment, type: :model do
  include ActionDispatch::TestProcess::FixtureFile

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

  it "stores uploaded files under family/communication key prefixes" do
    attachment = create(:attachment)
    allow(SecureRandom).to receive(:uuid).and_return("uuid-123")

    file = fixture_file_upload("sample.txt", "text/plain")
    attachment.attach_uploaded_files!([file])

    key = attachment.files.first.blob.key
    expect(key).to start_with("families/#{attachment.child.parent.family_id}/communications/#{attachment.communication_id}/files/")
    expect(key).to include("uuid-123")
  end

  it "infers content type from uploaded files" do
    attachment = create(:attachment, content_type: "unknown")
    file = fixture_file_upload("sample.txt", "text/plain")

    attachment.attach_uploaded_files!([file])

    expect(attachment.reload.content_type).to eq("document")
  end

  it "applies sensible defaults when metadata is not explicitly provided" do
    communication = create(:communication)
    attachment = Attachment.create!(communication: communication)

    expect(attachment.source_type).to eq("upload")
    expect(attachment.content_type).to eq("unknown")
    expect(attachment.processing_state).to eq("pending")
    expect(attachment.ai_status).to eq("pending")
    expect(attachment.captured_at).to be_present
    expect(attachment.occurred_at).to be_present
  end

  it "stores raw email under family/communication key prefixes" do
    attachment = create(:attachment)
    allow(SecureRandom).to receive(:uuid).and_return("uuid-raw")

    attachment.attach_raw_email_io!(io: StringIO.new("raw email body"), filename: "message.eml")

    key = attachment.raw_email.blob.key
    expect(key).to start_with("families/#{attachment.child.parent.family_id}/communications/#{attachment.communication_id}/raw_email/")
    expect(key).to include("uuid-raw")
  end
end
