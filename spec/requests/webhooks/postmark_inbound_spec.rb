require "rails_helper"

RSpec.describe "Postmark inbound webhook", type: :request do
  before { clear_enqueued_jobs }

  it "creates attachment and enqueues ordered communication reprocessing" do
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
    end.to have_enqueued_job(AI::ReprocessCommunicationJob)

    expect(response).to have_http_status(:ok)
    expect(child.attachments.count).to eq(1)
    attachment = child.attachments.last
    expect(attachment.source_type).to eq("email")
    expect(attachment.content_type).to eq("message")
    expect(attachment.files).to be_attached
    expect(attachment.files.first.filename.to_s).to start_with("email-body-")
    expect(attachment.files.first.filename.to_s).to end_with(".txt")
    expect(attachment.files.first.blob.content_type).to eq("text/plain")
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
