require "base64"
require "stringio"

module Webhooks
  class PostmarkInboundController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      return head :unauthorized unless valid_webhook_auth?

      payload = parsed_payload
      inbound_email = extract_inbound_email(payload)
      child = find_child_from_email(inbound_email)

      return render json: { status: "ignored" }, status: :not_found unless child

      correspondent = find_or_create_correspondent(payload, child)
      communication = child.communications.create!(
        source: "postmark",
        from_email: payload["From"],
        from_name: payload["FromName"],
        subject: payload["Subject"],
        received_at: payload["Date"] || Time.current,
        body_text: payload["TextBody"],
        body_html: payload["HtmlBody"],
        raw_payload: payload,
        ai_status: "pending",
        correspondents: [correspondent]
      )

      artifact = communication.artifacts.create!(
        child: child,
        source_type: "email",
        content_type: "message",
        title: payload["Subject"].presence || "School Email",
        source: "postmark",
        from_email: payload["From"],
        from_name: payload["FromName"],
        subject: payload["Subject"],
        occurred_at: payload["Date"] || Time.current,
        captured_at: Time.current,
        body_text: payload["TextBody"],
        body_html: payload["HtmlBody"],
        raw_payload: payload,
        processing_state: "pending",
        ai_status: "pending"
      )

      attach_raw_email(artifact, payload)
      create_attachment_artifacts(communication, payload, child)

      Artifacts::ProcessArtifactJob.perform_later(artifact.id)

      render json: { status: "ok" }
    rescue JSON::ParserError
      render json: { error: "invalid_json" }, status: :bad_request
    end

    private
    # Accept Basic Auth (preferred) and keep token header fallback for compatibility.
    def valid_webhook_auth?
      basic_auth_valid? || token_header_valid?
    end

    def basic_auth_valid?
      username = ENV["POSTMARK_WEBHOOK_USERNAME"].presence
      password = ENV["POSTMARK_WEBHOOK_SECRET"].presence

      return false if username.blank? || password.blank?

      authenticate_with_http_basic do |supplied_user, supplied_pass|
        secure_compare(supplied_user, username) && secure_compare(supplied_pass, password)
      end
    end

    def token_header_valid?
      supplied = request.headers["X-Postmark-Webhook-Token"].to_s
      expected = ENV.fetch("POSTMARK_WEBHOOK_SECRET", "")

      return false if expected.blank? || supplied.bytesize != expected.bytesize

      secure_compare(supplied, expected)
    end

    def secure_compare(a, b)
      return false if a.blank? || b.blank? || a.bytesize != b.bytesize

      ActiveSupport::SecurityUtils.secure_compare(a, b)
    end

    def extract_inbound_email(payload)
      to_full = payload["ToFull"]
      if to_full.is_a?(Array)
        first_email = to_full.filter_map { |entry| entry.is_a?(Hash) ? entry["Email"] : nil }.first
        return first_email if first_email.present?
      end

      payload["OriginalRecipient"] || payload["To"] || ""
    end

    def find_child_from_email(email)
      return nil if email.blank?

      local = email.to_s.split("@").first
      parts = local.to_s.split("-")

      if parts.size >= 2 && parts.last.to_i.positive?
        child = Child.find_by(id: parts.last.to_i)
        return child if child.present?
      end

      Child.find_by(inbound_alias: local)
    end

    def create_attachment_artifacts(communication, payload, child)
      attachments = payload["Attachments"]
      return unless attachments.is_a?(Array)

      attachments.each do |att|
        next unless att.is_a?(Hash) && att["Content"].present?

        artifact = communication.artifacts.new(
          child: child,
          source_type: "email",
          content_type: infer_content_type(att["ContentType"]),
          title: att["Name"].presence || "Email Attachment",
          subject: communication.subject,
          occurred_at: payload["Date"] || Time.current,
          captured_at: Time.current,
          processing_state: "pending",
          ai_status: "pending"
        )

        next unless artifact.save

        artifact.files.attach(
          io: StringIO.new(Base64.decode64(att["Content"])),
          filename: att["Name"].presence || "attachment",
          content_type: att["ContentType"].presence || "application/octet-stream"
        )

        Artifacts::ProcessArtifactJob.perform_later(artifact.id)
      end
    end

    def attach_raw_email(artifact, payload)
      raw_email = payload["RawEmail"]
      return if raw_email.blank?

      artifact.raw_email.attach(
        io: StringIO.new(raw_email),
        filename: "raw-email-#{artifact.id}.eml",
        content_type: "message/rfc822"
      )
    end

    def infer_content_type(mime)
      return "pdf" if mime.to_s == "application/pdf"
      return "image" if mime.to_s.start_with?("image/")
      return "document" if mime.to_s.start_with?("text/") || mime.to_s.include?("word") || mime.to_s.include?("officedocument")

      "unknown"
    end

    def parsed_payload
      params_hash =
        if request.request_parameters.respond_to?(:to_unsafe_h)
          request.request_parameters.to_unsafe_h
        else
          request.request_parameters
        end

      params_hash.presence || JSON.parse(request.raw_post)
    end

    def find_or_create_correspondent(payload, child)
      email = payload["From"].to_s.downcase.presence
      user = email.present? ? User.find_by(email: email) : nil

      Correspondent.find_or_create_by!(email: email, user: user) do |record|
        record.name = payload["FromName"].presence || email
        record.family = child.parent.family
      end
    end
  end
end
