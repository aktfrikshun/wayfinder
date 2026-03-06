require "rails_helper"

RSpec.describe User, type: :model do
  it "is valid with a supported role" do
    user = build(:user, role: :admin)

    expect(user).to be_valid
    expect(user.role_label).to eq("ADMIN")
  end

  it "rejects unsupported roles" do
    user = build(:user)

    expect { user.role = "principal" }.to raise_error(ArgumentError, /is not a valid role/)
  end

  it "creates a linked correspondent record on save" do
    user = create(:user, email: "parent-profile@example.com")

    expect(user.correspondent).to be_present
    expect(user.correspondent.email).to eq("parent-profile@example.com")
  end

  it "defaults role to parent when omitted" do
    user = User.create!(
      email: "default-parent@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )

    expect(user.role).to eq("parent")
    expect(user.role_label).to eq("PARENT")
  end
end
