require "rails_helper"

RSpec.describe AI::ReprocessCommunicationJob, type: :job do
  it "processes attachments first, then extracts communication AI metadata" do
    communication = create(:communication)
    first = create(:attachment, communication: communication, child: communication.child)
    second = create(:attachment, communication: communication, child: communication.child)

    expect(Attachments::ProcessAttachmentJob).to receive(:perform_now).with(first.id).ordered
    expect(Attachments::ProcessAttachmentJob).to receive(:perform_now).with(second.id).ordered
    expect(AI::ExtractCommunicationJob).to receive(:perform_now).with(communication.id).ordered

    described_class.perform_now(communication.id)
  end
end
