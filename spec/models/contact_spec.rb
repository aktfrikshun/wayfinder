require "rails_helper"

RSpec.describe Contact, type: :model do
  it "enforces email uniqueness within the same family" do
    family = create(:family)
    create(:contact, family: family, email: "same@example.com")

    duplicate = build(:contact, family: family, email: "same@example.com")
    expect(duplicate).not_to be_valid
  end

  it "enforces phone uniqueness within the same family" do
    family = create(:family)
    create(:contact, family: family, phone: "555-111-2222")

    duplicate = build(:contact, family: family, phone: "555-111-2222")
    expect(duplicate).not_to be_valid
  end

  it "allows same email and phone across different families" do
    create(:contact, email: "shared@example.com", phone: "555-000-1000")
    other = build(:contact, email: "shared@example.com", phone: "555-000-1000")

    expect(other).to be_valid
  end
end
