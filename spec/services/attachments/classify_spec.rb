require "rails_helper"

RSpec.describe Attachments::Classify, type: :service do
  it "classifies based on extracted text" do
    attachment = create(:attachment, normalized_text: "Homework due Friday and assignment details")

    described_class.call(attachment)

    attachment.reload
    expect(attachment.system_category).to eq("assignment")
    expect(attachment.tags).to include("homework", "assignment")
    expect(attachment.category_confidence).to be >= 0.55
  end
end
