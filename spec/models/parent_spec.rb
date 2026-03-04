require "rails_helper"

RSpec.describe Parent, type: :model do
  it "requires an email" do
    parent = described_class.new(name: "Test")

    expect(parent).not_to be_valid
    expect(parent.errors[:email]).to include("can't be blank")
  end

  it "enforces unique email" do
    create(:parent, email: "dupe@example.com")
    parent = build(:parent, email: "dupe@example.com")

    expect(parent).not_to be_valid
  end
end
