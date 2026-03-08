require "rails_helper"

RSpec.describe "Admin child chats", type: :request do
  it "allows admin to send chat messages for a child" do
    admin = create(:user, :admin, email: "admin-chat@example.com")
    child = create(:child)
    sign_in(admin)

    allow(ChatSessions::AgentResponder).to receive(:call).and_return(
      answer: "Focus on reading fluency and routines.",
      suggested_title: "Reading Support Plan",
      references: [{ "title" => "CDC Child Development", "url" => "https://www.cdc.gov/ncbddd/childdevelopment/" }],
      warning: "AI responses can be wrong. Please verify important guidance with trusted professionals."
    )

    post child_chats_path(child), params: { opening_prompt: "What should we work on next?" }
    chat = child.communications.where(source: Communication::CHAT_SOURCE).last
    expect(chat).to be_present

    post messages_child_chat_path(child, chat), params: { question: "Any general growth advice?" }
    expect(response).to redirect_to(child_chat_path(child, chat))

    chat.reload
    expect(chat.chat_messages.length).to eq(4)
    expect(chat.chat_messages.last["references"]).to be_present
  end
end
