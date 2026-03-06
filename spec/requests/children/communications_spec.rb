require "rails_helper"

RSpec.describe "Child artifacts API", type: :request do
  it "returns latest 50 artifacts ordered by occurred_at then captured_at" do
    child = create(:child)
    create_list(:artifact, 55, child: child)

    get "/children/#{child.id}/artifacts"

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body)

    expect(payload.size).to eq(50)
    expect(payload.first.keys).to include(
      "id", "source_type", "content_type", "title", "subject",
      "occurred_at", "captured_at", "processing_state", "ai_status",
      "effective_category", "tags", "summary"
    )
  end
end
