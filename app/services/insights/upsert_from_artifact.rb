module Insights
  class UpsertFromArtifact
    def self.call(artifact)
      new(artifact).call
    end

    def initialize(artifact)
      @artifact = artifact
      @payload = artifact.extracted_payload.to_h
    end

    def call
      return unless artifact.child && artifact.extracted_payload.present?

      Insight.where(artifact_id: artifact.id).first_or_initialize.tap do |insight|
        insight.child = artifact.child
        insight.title = build_title
        insight.body = build_body
        insight.priority = payload[:priority]
        insight.confidence = payload[:signals].is_a?(Array) ? average_confidence(payload[:signals]) : nil
        insight.signals = extract_signals
        insight.status = "active"
        insight.save!
      end
    end

    private

    attr_reader :artifact, :payload

    def build_title
      payload[:summary].presence || artifact.display_title
    end

    def build_body
      payload[:category_rationale].presence || payload[:summary]
    end

    def extract_signals
      signals = payload[:signals]
      return {} unless signals.is_a?(Array)

      { items: signals }
    end

    def average_confidence(signals)
      numeric = signals.map { |s| s[:confidence] || s['confidence'] }.compact
      return nil if numeric.empty?

      numeric.sum.to_f / numeric.size
    end
  end
end
