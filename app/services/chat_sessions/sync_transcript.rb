require "stringio"

module ChatSessions
  class SyncTranscript
    def self.call(communication)
      new(communication).call
    end

    def initialize(communication)
      @communication = communication
    end

    def call
      transcript_attachment = find_or_build_transcript_attachment
      transcript_attachment.body_text = transcript_text
      transcript_attachment.title = "Chat Transcript"
      transcript_attachment.description = "Transcript for #{communication.display_title}"
      transcript_attachment.save!

      transcript_attachment.files.purge if transcript_attachment.files.attached?
      transcript_attachment.attach_file_io!(
        io: StringIO.new(transcript_text),
        filename: "chat-transcript-communication-#{communication.id}.txt",
        content_type: "text/plain"
      )

      transcript_attachment
    end

    private

    attr_reader :communication

    def find_or_build_transcript_attachment
      existing = communication.attachments.find do |att|
        att.metadata.to_h["chat_transcript"] == true
      end
      return existing if existing

      communication.attachments.new(
        child: communication.child,
        source_type: "system",
        content_type: "message",
        source: "agent_chat",
        subject: communication.subject,
        captured_at: Time.current,
        occurred_at: Time.current,
        processing_state: "pending",
        ai_status: "pending",
        metadata: { "chat_transcript" => true }
      )
    end

    def transcript_text
      lines = []
      lines << "Chat Title: #{communication.display_title}"
      lines << "Child: #{communication.child.name}"
      lines << "Generated At: #{Time.current.iso8601}"
      lines << ""
      lines << "Transcript:"

      communication.chat_messages.each do |msg|
        role = msg["role"].to_s.upcase
        at = msg["at"].presence || "-"
        lines << "[#{at}] #{role}: #{msg['content']}"

        if msg["references"].is_a?(Array) && msg["references"].any?
          lines << "References:"
          msg["references"].each do |ref|
            lines << "- #{ref['title']}: #{ref['url']}"
          end
        end
        lines << "Warning: #{msg['warning']}" if msg["warning"].present?
        lines << ""
      end

      lines.join("\n")
    end
  end
end
