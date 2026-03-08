require "rails_helper"

RSpec.describe "Home landing", type: :request do
  it "shows the public landing page to unauthenticated users" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Support Your Child's Growth With Everyone Working Together")
    expect(response.body).to include("Features and Benefits")
  end

  it "redirects signed-in admins to dashboard" do
    sign_in(create(:user, :admin))

    get root_path

    expect(response).to redirect_to(dashboard_path)
  end

  it "redirects signed-in parents to parent dashboard" do
    parent = create(:parent, email: "landing-parent@example.com")
    sign_in(create(:user, role: :parent, email: parent.email))

    get root_path

    expect(response).to redirect_to(parent_root_path)
  end
end
