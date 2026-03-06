require "rails_helper"

RSpec.describe Communication, type: :model do
  it "allows only known ai statuses" do
    communication = build(:communication, ai_status: "unknown")

    expect(communication).not_to be_valid
    expect(communication.errors[:ai_status]).to include("is not included in the list")
  end

  it "requires at least one correspondent" do
    communication = build(:communication, from_email: nil, from_name: nil)
    communication.correspondents.clear

    expect(communication).not_to be_valid
    expect(communication.errors[:correspondents]).to include("must include at least one")
  end
end
