require "rails_helper"

RSpec.describe Communication, type: :model do
  it "allows only known ai statuses" do
    communication = build(:communication, ai_status: "unknown")

    expect(communication).not_to be_valid
    expect(communication.errors[:ai_status]).to include("is not included in the list")
  end
end
