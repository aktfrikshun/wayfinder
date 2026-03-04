module Webhooks
  class PostmarkInboundController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      return head :unauthorized unless valid_webhook_token?

      payload = parsed_payload
      inbound_email = extract_inbound_email(payload)
      child = Child.find_by(inbound_alias: inbound_alias_from_email(inbound_email))

      return render json: { status: "ignored" }, status: :not_found unless child

      communication = child.communications.create!(
        source: "postmark",
        from_email: payload["From"],
        from_name: payload["FromName"],
        subject: payload["Subject"],
        received_at: payload["Date"] || Time.current,
        body_text: payload["TextBody"],
        body_html: payload["HtmlBody"],
        raw_payload: payload,
        ai_status: "pending"
      )

      AI::ExtractCommunicationJob.perform_later(communication.id)

      render json: { status: "ok" }
    rescue JSON::ParserError
      render json: { error: "invalid_json" }, status: :bad_request
    end

    private

    def valid_webhook_token?
      supplied = request.headers["X-Postmark-Webhook-Token"].to_s
      expected = ENV.fetch("POSTMARK_WEBHOOK_SECRET", "")

      return false if expected.blank? || supplied.bytesize != expected.bytesize

      ActiveSupport::SecurityUtils.secure_compare(supplied, expected)
    end

    def extract_inbound_email(payload)
      to_full = payload["ToFull"]
      if to_full.is_a?(Array)
        first_email = to_full.filter_map { |entry| entry.is_a?(Hash) ? entry["Email"] : nil }.first
        return first_email if first_email.present?
      end

      payload["OriginalRecipient"] || payload["To"] || ""
    end

    def inbound_alias_from_email(email)
      return nil if email.blank?

      email.to_s.split("@").first
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
  end
end
