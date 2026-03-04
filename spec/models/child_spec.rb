require "rails_helper"

RSpec.describe Child, type: :model do
  it "requires a name" do
    child = described_class.new(parent: create(:parent), name: nil)

    expect(child).not_to be_valid
    expect(child.errors[:name]).to include("can't be blank")
  end

  it "enforces unique inbound alias" do
    create(:child, inbound_alias: "zammy")
    child = build(:child, inbound_alias: "zammy")

    expect(child).not_to be_valid
  end
end
