module Webhooks
  class PostmarkEventsController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      return head :unauthorized unless valid_webhook_token?

      payload = parsed_payload
      PostmarkEvent.create!(
        event_type: payload["RecordType"].presence || payload["Type"].presence || "unknown",
        message_id: payload["MessageID"],
        recipient: payload["Recipient"],
        recorded_at: parse_time(payload["ReceivedAt"] || payload["DeliveredAt"] || payload["BouncedAt"]),
        payload: payload
      )

      render json: { status: "ok" }
    rescue JSON::ParserError
      render json: { error: "invalid_json" }, status: :bad_request
    end

    private

    def valid_webhook_token?
      supplied = request.headers["X-Postmark-Webhook-Token"].to_s
      expected = ENV["POSTMARK_EVENTS_WEBHOOK_SECRET"].presence || ENV.fetch("POSTMARK_WEBHOOK_SECRET", "")

      return false if expected.blank? || supplied.bytesize != expected.bytesize

      ActiveSupport::SecurityUtils.secure_compare(supplied, expected)
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

    def parse_time(value)
      return nil if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError
      nil
    end
  end
end
