require "rails_helper"

RSpec.describe "Portal routing", type: :request do
  it "redirects parent users to parent dashboard and provisions a parent profile" do
    user = create(:user, role: :parent, email: "new-parent@example.com")
    Parent.where(email: user.email).delete_all
    sign_in(user)

    get portal_path

    expect(response).to redirect_to(parent_root_path)
    expect(Parent.find_by(email: user.email)).to be_present
  end
end
