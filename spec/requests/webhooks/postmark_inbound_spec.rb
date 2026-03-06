require "rails_helper"

RSpec.describe "Postmark inbound webhook", type: :request do
  before { clear_enqueued_jobs }

  it "creates artifact and enqueues processing job" do
    alias_name = "alias#{SecureRandom.hex(4)}"
    child = create(:child, inbound_alias: alias_name)

    expect do
      post "/webhooks/postmark/inbound",
           params: {
             From: "teacher@example.org",
             FromName: "Ms. Carter",
             Subject: "Math reminder",
             Date: "2026-03-04T12:00:00Z",
             ToFull: [{ Email: "#{alias_name}@inbound.wayfinder.local" }],
             TextBody: "Complete page 12",
             HtmlBody: "<p>Complete page 12</p>"
           }.to_json,
           headers: {
             "CONTENT_TYPE" => "application/json",
             "X-Postmark-Webhook-Token" => "secret"
           }
    end.to have_enqueued_job(Artifacts::ProcessArtifactJob)

    expect(response).to have_http_status(:ok)
    expect(child.artifacts.count).to eq(1)
    artifact = child.artifacts.last
    expect(artifact.source_type).to eq("email")
    expect(artifact.content_type).to eq("message")
  end

  it "returns unauthorized for invalid token" do
    post "/webhooks/postmark/inbound", params: {}.to_json, headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:unauthorized)
  end

  around do |example|
    original = ENV["POSTMARK_WEBHOOK_SECRET"]
    ENV["POSTMARK_WEBHOOK_SECRET"] = "secret"
    example.run
    ENV["POSTMARK_WEBHOOK_SECRET"] = original
  end
end
