require "rails_helper"

RSpec.describe Artifacts::ExtractText, type: :service do
  it "uses native extraction for message artifacts" do
    artifact = create(:artifact, content_type: "message", body_text: "Weekly classroom update")

    described_class.call(artifact)

    artifact.reload
    expect(artifact.text_extraction_method).to eq("native")
    expect(artifact.normalized_text).to include("Weekly classroom update")
    expect(artifact.ocr_text).to be_nil
  end

  it "falls back to ocr for low-quality pdf extraction" do
    artifact = create(
      :artifact,
      content_type: "pdf",
      metadata: { "native_pdf_text" => "", "ocr_text" => "OCR recovered report card details" }
    )

    described_class.call(artifact)

    artifact.reload
    expect(artifact.text_extraction_method).to eq("native_plus_ocr")
    expect(artifact.ocr_text).to include("OCR recovered")
    expect(artifact.normalized_text).to include("OCR recovered")
  end
end
