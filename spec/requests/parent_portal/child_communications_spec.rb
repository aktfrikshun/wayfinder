require "rails_helper"

RSpec.describe "Parent child communication management", type: :request do
  include ActionDispatch::TestProcess::FixtureFile

  before { clear_enqueued_jobs }

  it "allows parent to create communication and manage attachments" do
    parent = create(:parent, email: "parent-manage@example.com")
    child = create(:child, parent: parent)
    user = create(:user, role: :parent, email: parent.email)
    sign_in(user)

    expect do
      post parent_child_communications_path(child), params: {
        communication: {
          subject: "Teacher update",
          body_text: "We discussed reading progress.",
          received_at: Time.current,
          correspondent_ids: []
        }
      }
    end.to have_enqueued_job(AI::ReprocessCommunicationJob)

    communication = child.communications.order(:created_at).last
    expect(response).to redirect_to(edit_parent_child_communication_path(child, communication))
    expect(communication).to be_present
    expect(communication.correspondents).to include(user.correspondent)

    file = fixture_file_upload("sample.txt", "text/plain")

    expect do
      post attachments_parent_child_communication_path(child, communication), params: {
        attachment: {
          title: "Attachment",
          files: ["", file]
        }
      }
    end.to change(Attachment, :count).by(1).and have_enqueued_job(AI::ReprocessCommunicationJob).with(communication.id)

    attachment = communication.attachments.order(:created_at).last
    expect(attachment.files.count).to eq(1)

    expect do
      delete attachment_parent_child_communication_path(child, communication, attachment_id: attachment.id)
    end.to change(Attachment, :count).by(-1).and have_enqueued_job(AI::ReprocessCommunicationJob).with(communication.id)
  end

  it "enqueues ordered reprocess from the communication reprocess endpoint" do
    parent = create(:parent, email: "parent-reprocess@example.com")
    child = create(:child, parent: parent)
    user = create(:user, role: :parent, email: parent.email)
    sign_in(user)
    communication = create(:communication, child: child, correspondents_count: 0)
    communication.correspondents << user.correspondent

    expect do
      post reprocess_parent_child_communication_path(child, communication)
    end.to have_enqueued_job(AI::ReprocessCommunicationJob).with(communication.id)

    expect(response).to redirect_to(parent_child_communication_path(child, communication))
  end
end
