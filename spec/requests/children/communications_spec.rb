require "rails_helper"

RSpec.describe "Child communications API", type: :request do
  it "returns latest 50 communications" do
    child = create(:child)
    create_list(:communication, 55, child: child)

    get "/children/#{child.id}/communications"

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body)

    expect(payload.size).to eq(50)
    expect(payload.first.keys).to include("id", "subject", "received_at", "ai_status", "ai_extracted")
    expect(payload.first.fetch("ai_extracted")).to have_key("summary")
  end
end
