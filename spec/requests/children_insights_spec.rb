require "rails_helper"

RSpec.describe "Admin child insights", type: :request do
  it "shows attachment AI payload and child insights" do
    sign_in(create(:user, :admin))

    child = create(:child)
    communication = create(:communication, child: child)
    attachment = create(
      :attachment,
      communication: communication,
      child: child,
      extracted_payload: { "summary" => "Needs reading support" }
    )
    Insight.create!(
      child: child,
      attachment: attachment,
      title: "Reading concern",
      body: "Follow up with teacher",
      status: "active",
      priority: "medium"
    )

    get insights_child_path(child)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Attachment AI Extracted Data")
    expect(response.body).to include("Reading concern")
    expect(response.body).to include("Needs reading support")
  end
end
