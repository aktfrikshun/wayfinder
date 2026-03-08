require "rails_helper"

RSpec.describe "Parent child chats", type: :request do
  include ActiveJob::TestHelper

  it "allows a parent to start a chat and stores transcript attachment" do
    parent = create(:parent, email: "chat-parent@example.com")
    child = create(:child, parent: parent)
    user = create(:user, role: :parent, email: parent.email)
    sign_in(user)

    allow(ChatSessions::AgentResponder).to receive(:call).and_return(
      answer: "Q3 improved over Q2 in Language Arts.",
      suggested_title: "Progress Report Discussion",
      references: [],
      warning: nil
    )

    post parent_child_chats_path(child), params: { opening_prompt: "How is Zammy doing this quarter?" }

    expect(response).to redirect_to(parent_child_chat_path(child, Communication.last))
    chat = child.communications.where(source: Communication::CHAT_SOURCE).last
    expect(chat).to be_present
    expect(chat.chat_messages.length).to eq(2)

    transcript = chat.attachments.find { |a| a.metadata.to_h["chat_transcript"] == true }
    expect(transcript).to be_present
    expect(transcript.files).to be_attached
  end
end
