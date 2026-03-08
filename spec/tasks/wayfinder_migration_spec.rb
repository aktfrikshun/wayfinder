require "rails_helper"
require "rake"

RSpec.describe "wayfinder:migrate_communications_to_attachments" do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  before do
    Rake::Task["wayfinder:migrate_communications_to_attachments"].reenable
  end

  it "migrates communication rows into attachments" do
    communication = create(:communication, subject: "Science update", ai_status: "complete", ai_extracted: { "summary" => "Lab due" })

    expect do
      Rake::Task["wayfinder:migrate_communications_to_attachments"].invoke
    end.to change(Attachment, :count).by(1)

    attachment = Attachment.find_by(child_id: communication.child_id, subject: "Science update")
    expect(attachment).to be_present
    expect(attachment.source_type).to eq("email")
    expect(attachment.content_type).to eq("message")
    expect(attachment.extracted_payload).to include("summary" => "Lab due")
  end
end
