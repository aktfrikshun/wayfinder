require "rails_helper"

RSpec.describe "Parent child insights", type: :request do
  it "shows attachment AI payload and child insights to the owning parent" do
    parent = create(:parent, email: "parent-insights@example.com")
    child = create(:child, parent: parent)
    user = create(:user, role: :parent, email: parent.email)
    sign_in(user)

    communication = create(:communication, child: child)
    attachment = create(
      :attachment,
      communication: communication,
      child: child,
      extracted_payload: { "summary" => "Math progress trend detected" }
    )
    Insight.create!(
      child: child,
      attachment: attachment,
      title: "Math trend",
      body: "Continue weekly review",
      status: "active",
      priority: "low"
    )

    get insights_parent_child_path(child)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Attachment AI Extracted Data")
    expect(response.body).to include("Math trend")
    expect(response.body).to include("Math progress trend detected")
  end
end
