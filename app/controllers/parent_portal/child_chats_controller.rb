module ParentPortal
  class ChildChatsController < BaseController
    before_action :set_child
    before_action :set_chat, only: %i[show messages]

    def index
      @chats = scoped_chats.order(updated_at: :desc)
    end

    def show
      @messages = @chat.chat_messages
    end

    def create
      opening_prompt = params[:opening_prompt].to_s.strip
      title = opening_prompt.split(/\s+/).first(8).join(" ").presence || "New Child Growth Chat"

      @chat = @child.communications.new(
        source: Communication::CHAT_SOURCE,
        subject: title,
        description: "AI child growth support chat",
        from_email: current_correspondent.email,
        from_name: current_correspondent.name,
        received_at: Time.current,
        ai_status: "complete",
        raw_payload: { "chat_messages" => [] },
        correspondents: [current_correspondent]
      )

      if @chat.save
        process_question!(@chat, opening_prompt) if opening_prompt.present?
        redirect_to parent_child_chat_path(@child, @chat), notice: "Chat started."
      else
        @chats = scoped_chats.order(updated_at: :desc)
        render :index, status: :unprocessable_entity
      end
    end

    def messages
      question = params[:question].to_s.strip
      if question.blank?
        redirect_to parent_child_chat_path(@child, @chat), alert: "Please enter a question."
        return
      end

      process_question!(@chat, question)
      redirect_to parent_child_chat_path(@child, @chat), notice: "Response added."
    end

    private

    def set_child
      @child = @parent.children.find(params[:child_id])
    end

    def set_chat
      @chat = scoped_chats.find(params[:id])
    end

    def scoped_chats
      @child.communications
        .where(source: Communication::CHAT_SOURCE)
        .joins(:correspondents)
        .where(correspondents: { id: current_correspondent.id })
        .distinct
    end

    def process_question!(chat, question)
      chat.append_chat_message!(role: "parent", content: question)

      response = ChatSessions::AgentResponder.call(
        child: @child,
        communication: chat,
        question: question
      )

      if chat.subject.blank? || chat.subject == "New Child Growth Chat"
        inferred = response[:suggested_title].to_s.split(/\s+/).first(10).join(" ").presence
        chat.update!(subject: inferred) if inferred.present?
      end

      chat.append_chat_message!(
        role: "agent",
        content: response[:answer],
        references: response[:references],
        warning: response[:warning]
      )
      ChatSessions::SyncTranscript.call(chat)
    end
  end
end
