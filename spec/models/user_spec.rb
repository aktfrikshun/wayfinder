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
end
