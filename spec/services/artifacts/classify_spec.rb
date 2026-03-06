require "rails_helper"

RSpec.describe Artifacts::Classify, type: :service do
  it "classifies based on extracted text" do
    artifact = create(:artifact, normalized_text: "Homework due Friday and assignment details")

    described_class.call(artifact)

    artifact.reload
    expect(artifact.system_category).to eq("assignment")
    expect(artifact.tags).to include("homework", "assignment")
    expect(artifact.category_confidence).to be >= 0.55
  end
end
