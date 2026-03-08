require "rails_helper"

RSpec.describe "Admin reprocessing controls", type: :request do
  before { clear_enqueued_jobs }

  it "queues child-level insight regeneration" do
    sign_in(create(:user, :admin))
    child = create(:child)
    communication = create(:communication, child: child)

    expect do
      post regenerate_insights_child_path(child)
    end.to have_enqueued_job(AI::ReprocessCommunicationJob).with(communication.id)

    expect(response).to redirect_to(child_path(child))
  end

  it "queues communication-level reprocessing" do
    sign_in(create(:user, :admin))
    communication = create(:communication)

    expect do
      post reprocess_communication_path(communication)
    end.to have_enqueued_job(AI::ReprocessCommunicationJob).with(communication.id)

    expect(response).to redirect_to(communication_path(communication))
  end
end
