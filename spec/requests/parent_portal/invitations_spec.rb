require "rails_helper"

RSpec.describe "Parent invitations", type: :request do
  include ActiveJob::TestHelper

  before do
    ActionMailer::Base.deliveries.clear
    clear_enqueued_jobs
  end

  it "allows a parent to invite a teacher and sends email" do
    parent = create(:parent, email: "inviter@example.com")
    user = create(:user, role: :parent, email: parent.email)
    sign_in(user)

    expect do
      perform_enqueued_jobs do
        post parent_invitations_path, params: {
          invite: {
            name: "Teacher User",
            email: "teacher-invite@example.com",
            role: "teacher"
          }
        }
      end
    end.to change(User, :count).by(1)

    invited = User.find_by(email: "teacher-invite@example.com")
    expect(invited).to be_present
    expect(invited.role).to eq("teacher")
    expect(invited.must_change_password).to be(true)
    expect(invited.invited_by_id).to eq(user.id)
    expect(invited.correspondent.family_id).to eq(parent.family_id)

    expect(response).to redirect_to(parent_invitations_path)
    expect(ActionMailer::Base.deliveries.last&.subject).to eq("You're invited to Wayfinder")
  end

  it "creates a parent profile when inviting another parent" do
    parent = create(:parent, email: "parent-inviter@example.com")
    user = create(:user, role: :parent, email: parent.email)
    sign_in(user)

    post parent_invitations_path, params: {
      invite: {
        name: "Second Parent",
        email: "second-parent@example.com",
        role: "parent"
      }
    }

    invited = User.find_by(email: "second-parent@example.com")
    expect(invited).to be_present

    invited_parent = Parent.find_by(email: invited.email)
    expect(invited_parent).to be_present
    expect(invited_parent.family_id).to eq(parent.family_id)
  end
end
