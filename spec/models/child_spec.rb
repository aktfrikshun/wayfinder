require "rails_helper"

RSpec.describe Child, type: :model do
  it "requires a name" do
    child = described_class.new(parent: create(:parent), name: nil)

    expect(child).not_to be_valid
    expect(child.errors[:name]).to include("can't be blank")
  end

  it "enforces unique inbound alias" do
    alias_name = "alias-#{SecureRandom.hex(4)}"
    create(:child, inbound_alias: alias_name)
    child = build(:child, inbound_alias: alias_name)

    expect(child).not_to be_valid
  end

  it "tracks versions with paper trail" do
    child = create(:child, grade: "4")

    expect { child.update!(grade: "5", nickname: "Champ") }
      .to change { child.versions.count }.by(1)

    version = child.versions.last
    expect(version.event).to eq("update")
    expect(version.object_changes.to_s).to include("grade")
    expect(version.object_changes.to_s).to include("nickname")
  end
end
