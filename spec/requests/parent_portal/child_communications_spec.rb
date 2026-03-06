require "rails_helper"

RSpec.describe "Parent child communication management", type: :request do
  include ActionDispatch::TestProcess::FixtureFile

  it "allows parent to create communication and manage artifacts" do
    parent = create(:parent, email: "parent-manage@example.com")
    child = create(:child, parent: parent)
    user = create(:user, role: :parent, email: parent.email)
    sign_in(user)

    post parent_child_communications_path(child), params: {
      communication: {
        subject: "Teacher update",
        body_text: "We discussed reading progress.",
        received_at: Time.current,
        correspondent_ids: []
      }
    }

    communication = child.communications.order(:created_at).last
    expect(response).to redirect_to(edit_parent_child_communication_path(child, communication))
    expect(communication).to be_present
    expect(communication.correspondents).to include(user.correspondent)

    file = fixture_file_upload("sample.txt", "text/plain")

    expect do
      post artifacts_parent_child_communication_path(child, communication), params: {
        artifact: {
          title: "Attachment",
          files: [file]
        }
      }
    end.to change(Artifact, :count).by(1)

    artifact = communication.artifacts.order(:created_at).last
    expect(artifact.files.count).to eq(1)

    expect do
      delete artifact_parent_child_communication_path(child, communication, artifact_id: artifact.id)
    end.to change(Artifact, :count).by(-1)
  end
end
