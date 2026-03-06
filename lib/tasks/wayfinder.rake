namespace :wayfinder do
  desc "Migrate Communication rows to Artifact rows"
  task migrate_communications_to_artifacts: :environment do
    migrated = 0

    Communication.find_each do |communication|
      Artifact.find_or_create_by!(
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
      ) do |artifact|
        artifact.title = communication.subject.presence || "Inbound Email"
        artifact.extracted_payload = communication.ai_extracted || {}
        artifact.ai_status = communication.ai_status
        artifact.ai_raw_response = communication.ai_raw_response || {}
        artifact.ai_error = communication.ai_error
        artifact.system_category = "school_communication"
      end

      migrated += 1
    end

    puts "Migrated #{migrated} communication record(s) to artifacts."
  end
end
