require "rails_helper"

RSpec.describe "Parent portal dashboard", type: :request do
  it "renders successfully for a parent with a profile" do
    parent = create(:parent, email: "parent-dashboard@example.com")
    user = create(:user, role: :parent, email: parent.email)
    sign_in(user)

    get parent_root_path

    expect(response).to have_http_status(:ok)
  end
end
