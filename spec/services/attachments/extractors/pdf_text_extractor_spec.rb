require "rails_helper"

RSpec.describe Attachments::Extractors::PdfTextExtractor, type: :service do
  it "extracts text from PDF bytes using PDF::Reader" do
    attachment = create(:attachment, content_type: "pdf")
    extractor = described_class.new(attachment)
    reader = instance_double(PDF::Reader, pages: [double(text: "Quarter 1: A"), double(text: "Quarter 2: B")])

    allow(extractor).to receive(:download_primary_file).and_return("%PDF data")
    allow(PDF::Reader).to receive(:new).and_return(reader)

    result = extractor.call

    expect(result[:method]).to eq("native")
    expect(result[:raw_extracted_text]).to include("Quarter 1: A")
    expect(result[:normalized_text]).to include("Quarter 2: B")
  end
end
