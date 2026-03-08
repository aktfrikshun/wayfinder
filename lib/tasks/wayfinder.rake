namespace :wayfinder do
  desc "Migrate Communication rows to Attachment rows"
  task migrate_communications_to_attachments: :environment do
    migrated = 0

    Communication.find_each do |communication|
      Attachment.find_or_create_by!(
        communication_id: communication.id,
        child_id: communication.child_id,
        source_type: "email",
        content_type: "message",
        source: communication.source,
        from_email: communication.from_email,
        from_name: communication.from_name,
        subject: communication.subject,
        occurred_at: communication.received_at,
        captured_at: communication.created_at || communication.received_at || Time.current,
        body_text: communication.body_text,
        body_html: communication.body_html,
        raw_payload: communication.raw_payload || {}
      ) do |attachment|
        attachment.title = communication.subject.presence || "Inbound Email"
        attachment.extracted_payload = communication.ai_extracted || {}
        attachment.ai_status = communication.ai_status
        attachment.ai_raw_response = communication.ai_raw_response || {}
        attachment.ai_error = communication.ai_error
        attachment.system_category = "school_communication"
      end

      migrated += 1
    end

    puts "Migrated #{migrated} communication record(s) to attachments."
  end
end
