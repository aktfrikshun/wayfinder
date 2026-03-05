require "rails_helper"

RSpec.describe "Admin access", type: :request do
  let(:protected_paths) { [root_path, parents_path, children_path, communications_path, users_path] }

  it "redirects unauthenticated visitors to sign in" do
    protected_paths.each do |path|
      get path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  it "allows admins to access protected pages" do
    sign_in(create(:user, :admin))

    protected_paths.each do |path|
      get path
      expect(response).to have_http_status(:ok)
    end
  end

  it "rejects signed-in non-admin users" do
    protected_paths.each do |path|
      sign_in(create(:user, role: :parent))
      get path
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to eq("Admin access required.")
    end
  end
end
