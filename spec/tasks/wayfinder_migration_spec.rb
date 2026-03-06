require "rails_helper"
require "rake"

RSpec.describe "wayfinder:migrate_communications_to_artifacts" do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  before do
    Rake::Task["wayfinder:migrate_communications_to_artifacts"].reenable
  end

  it "migrates communication rows into artifacts" do
    communication = create(:communication, subject: "Science update", ai_status: "complete", ai_extracted: { "summary" => "Lab due" })

    expect do
      Rake::Task["wayfinder:migrate_communications_to_artifacts"].invoke
    end.to change(Artifact, :count).by(1)

    artifact = Artifact.find_by(child_id: communication.child_id, subject: "Science update")
    expect(artifact).to be_present
    expect(artifact.source_type).to eq("email")
    expect(artifact.content_type).to eq("message")
    expect(artifact.extracted_payload).to include("summary" => "Lab due")
  end
end
