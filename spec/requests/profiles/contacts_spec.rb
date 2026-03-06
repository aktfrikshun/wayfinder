require "rails_helper"

RSpec.describe "Profile correspondent settings", type: :request do
  it "redirects unauthenticated users" do
    get edit_profile_correspondent_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "allows a signed-in user to update their correspondent info" do
    user = create(:user)
    sign_in(user)

    patch profile_correspondent_path, params: {
      correspondent: {
        name: "Teacher Liaison",
        email: "liaison@example.org",
        phone: "555-222-1000"
      }
    }

    expect(response).to redirect_to(edit_profile_correspondent_path)
    user.reload
    expect(user.correspondent).to be_present
    expect(user.correspondent.name).to eq("Teacher Liaison")
    expect(user.correspondent.email).to eq("liaison@example.org")
    expect(user.correspondent.phone).to eq("555-222-1000")
  end
end
