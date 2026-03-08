require "rails_helper"

RSpec.describe Attachments::ExtractText, type: :service do
  it "uses native extraction for message attachments" do
    attachment = create(:attachment, content_type: "message", body_text: "Weekly classroom update")

    described_class.call(attachment)

    attachment.reload
    expect(attachment.text_extraction_method).to eq("native")
    expect(attachment.normalized_text).to include("Weekly classroom update")
    expect(attachment.ocr_text).to be_nil
  end

  it "falls back to ocr for low-quality pdf extraction" do
    attachment = create(
      :attachment,
      content_type: "pdf",
      metadata: { "native_pdf_text" => "", "ocr_text" => "OCR recovered report card details" }
    )

    described_class.call(attachment)

    attachment.reload
    expect(attachment.text_extraction_method).to eq("native_plus_ocr")
    expect(attachment.ocr_text).to include("OCR recovered")
    expect(attachment.normalized_text).to include("OCR recovered")
  end

  it "runs ocr path for image attachments" do
    attachment = create(:attachment, content_type: "image", metadata: { "ocr_text" => "Detected text from image" })

    described_class.call(attachment)

    attachment.reload
    expect(attachment.text_extraction_method).to eq("ocr")
    expect(attachment.ocr_text).to eq("Detected text from image")
    expect(attachment.normalized_text).to include("Detected text from image")
  end
end
