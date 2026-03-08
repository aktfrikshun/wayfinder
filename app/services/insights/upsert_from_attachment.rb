module Insights
  class UpsertFromAttachment
    def self.call(attachment)
      new(attachment).call
    end

    def initialize(attachment)
      @attachment = attachment
      @payload = attachment.extracted_payload.to_h.deep_symbolize_keys
    end

    def call
      return unless attachment.child && attachment.extracted_payload.present?

      Insight.where(attachment_id: attachment.id).first_or_initialize.tap do |insight|
        insight.child = attachment.child
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

    attr_reader :attachment, :payload

    def build_title
      grade_narrative? ? "Grade Trend Insight" : (payload[:summary].presence || attachment.display_title)
    end

    def build_body
      build_grade_narrative.presence || payload[:category_rationale].presence || payload[:summary]
    end

    def extract_signals
      signals = payload[:signals]
      return {} unless signals.is_a?(Array)

      { items: signals }
    end

    def average_confidence(signals)
      numeric = signals.map { |s| s.is_a?(Hash) ? (s[:confidence] || s["confidence"]) : nil }.compact
      return nil if numeric.empty?

      numeric.sum.to_f / numeric.size
    end

    def grade_narrative?
      tabular_data[:detected] == true && period_columns.length >= 2 && numeric_rows.any?
    end

    def build_grade_narrative
      return nil unless grade_narrative?

      latest = period_columns.last
      previous = period_columns[-2]

      latest_avg = average_for_period(latest)
      previous_avg = average_for_period(previous)
      return nil if latest_avg.nil? || previous_avg.nil?

      improved = subjects_improved(previous, latest)
      declined = subjects_declined(previous, latest)

      child_name = attachment.child.nickname.presence || attachment.child.name
      event_name = attachment.display_title.presence || "a recent report"
      year = tabular_data[:school_year].presence

      trend =
        if latest_avg > previous_avg
          "#{latest.upcase} grades were generally better than #{previous.upcase}."
        elsif latest_avg < previous_avg
          "#{latest.upcase} grades were generally lower than #{previous.upcase}."
        else
          "#{latest.upcase} grades were stable relative to #{previous.upcase}."
        end

      details = []
      details << "Improved: #{improved.join(', ')}." if improved.any?
      details << "Needs attention: #{declined.join(', ')}." if declined.any?

      recommendation =
        if declined.any?
          "I recommend focused review in #{declined.first(2).join(' and ')} to strengthen progress into the next period."
        else
          "I recommend maintaining current study routines and checking for steady progress into the next period."
        end

      parts = []
      parts << "Your child #{child_name} just received #{event_name}."
      parts << "School year #{year}." if year.present?
      parts << trend
      parts << details.join(" ") if details.any?
      parts << recommendation
      parts.join(" ")
    end

    def tabular_data
      @tabular_data ||= begin
        payload_tabular = payload[:tabular_data].is_a?(Hash) ? payload[:tabular_data] : {}
        meta_tabular = attachment.metadata.to_h["tabular_data"].is_a?(Hash) ? attachment.metadata.to_h["tabular_data"] : {}
        payload_tabular.deep_symbolize_keys.reverse_merge(meta_tabular.deep_symbolize_keys)
      end
    end

    def period_columns
      cols = Array(tabular_data[:period_columns]).map(&:to_s)
      return cols if cols.any?

      Array(tabular_data[:header]).map(&:to_s).select { |h| h.match?(/\Aq\d+\z/) }
    end

    def rows
      Array(tabular_data[:rows]).map { |row| row.is_a?(Hash) ? row.deep_symbolize_keys : {} }
    end

    def numeric_rows
      rows.select { |row| period_columns.any? { |col| numeric_score(row[col.to_sym] || row[col]) } }
    end

    def average_for_period(period_key)
      values = numeric_rows.map { |row| numeric_score(row[period_key.to_sym] || row[period_key]) }.compact
      return nil if values.empty?

      values.sum / values.length
    end

    def subjects_improved(previous, latest)
      rows.filter_map do |row|
        prev = numeric_score(row[previous.to_sym] || row[previous])
        cur = numeric_score(row[latest.to_sym] || row[latest])
        next unless prev && cur && cur > prev

        row[:metric_label] || row[:course] || row[:subject]
      end
    end

    def subjects_declined(previous, latest)
      rows.filter_map do |row|
        prev = numeric_score(row[previous.to_sym] || row[previous])
        cur = numeric_score(row[latest.to_sym] || row[latest])
        next unless prev && cur && cur < prev

        row[:metric_label] || row[:course] || row[:subject]
      end
    end

    def numeric_score(value)
      return nil if value.blank?

      cleaned = value.to_s.strip.gsub("*", "")
      return nil unless cleaned.match?(/\A\d+(\.\d+)?\z/)

      cleaned.to_f
    end
  end
end
