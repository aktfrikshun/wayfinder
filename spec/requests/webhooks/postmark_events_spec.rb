require "rails_helper"

RSpec.describe "Postmark event webhook", type: :request do
  it "persists event payload" do
    expect do
      post "/webhooks/postmark/events",
           params: {
             RecordType: "Delivery",
             MessageID: "message-123",
             Recipient: "parent@example.com",
             DeliveredAt: "2026-03-06T20:00:00Z"
           }.to_json,
           headers: {
             "CONTENT_TYPE" => "application/json",
             "X-Postmark-Webhook-Token" => "event-secret"
           }
    end.to change(PostmarkEvent, :count).by(1)

    event = PostmarkEvent.last
    expect(event.event_type).to eq("Delivery")
    expect(event.message_id).to eq("message-123")
    expect(response).to have_http_status(:ok)
  end

  it "rejects invalid tokens" do
    post "/webhooks/postmark/events", params: {}.to_json, headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:unauthorized)
  end

  around do |example|
    original = ENV["POSTMARK_EVENTS_WEBHOOK_SECRET"]
    ENV["POSTMARK_EVENTS_WEBHOOK_SECRET"] = "event-secret"
    example.run
    ENV["POSTMARK_EVENTS_WEBHOOK_SECRET"] = original
  end
end
