module Attachments
  class ExtractTables
    MAX_ROWS = 200

    def self.call(attachment)
      new(attachment).call
    end

    def initialize(attachment)
      @attachment = attachment
    end

    def call
      lines = source_text.split(/\r?\n/).map(&:rstrip).reject(&:blank?)
      segmented = lines.map { |line| split_columns(line) }
      candidates = segmented.select { |row| row.length >= 3 }

      return empty_result if candidates.empty?

      header_index = candidates.index { |row| header_like?(row) } || 0
      header = candidates[header_index]
      data_rows = candidates[(header_index + 1)..].to_a.first(MAX_ROWS)

      return empty_result if data_rows.empty?

      normalized_header = normalize_headers(header)
      rows = data_rows.filter_map { |row| normalize_row(row, normalized_header) }

      return empty_result if rows.empty?

      {
        "detected" => true,
        "source" => source_name,
        "school_year" => extract_school_year(lines),
        "period_columns" => normalized_header.select { |h| h.match?(/\Aq\d+\z/) },
        "header" => normalized_header,
        "rows" => rows,
        "row_count" => rows.length
      }
    end

    private

    attr_reader :attachment

    def source_text
      attachment.raw_extracted_text.presence || attachment.normalized_text.to_s
    end

    def source_name
      attachment.raw_extracted_text.present? ? "raw_extracted_text" : "normalized_text"
    end

    def split_columns(line)
      raw = line.to_s.strip
      return [] if raw.blank?

      with_separators = raw.split(/\t+| {2,}/).map(&:strip).reject(&:blank?)
      return with_separators if with_separators.length >= 3

      # OCR can flatten spacing; use a weak fallback that preserves likely rows.
      fallback = raw.split(/\s+/).map(&:strip).reject(&:blank?)
      fallback.length >= 3 ? fallback : []
    end

    def header_like?(row)
      text = row.join(" ").downcase
      text.match?(/\b(course|subject|teacher|quarter|grade|q1|q2|q3|q4)\b/)
    end

    def normalize_headers(header)
      header.map.with_index do |value, idx|
        cleaned = value.to_s.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
        cleaned = "col_#{idx + 1}" if cleaned.blank?

        quarter_match = cleaned.match(/\Aq(?:uarter)?_?([1-9]\d*)\z/)
        next "q#{quarter_match[1]}" if quarter_match
        next "q#{cleaned}" if cleaned.match?(/\A[1-9]\d*\z/)

        cleaned
      end
    end

    def normalize_row(row, header)
      return nil if row.blank?

      width = [header.length, row.length].max
      keys = header.dup
      while keys.length < width
        keys << "col_#{keys.length + 1}"
      end

      values = row.first(width)
      values += Array.new(width - values.length)

      mapped = keys.zip(values).to_h
      mapped["metric_label"] = mapped["course"] || mapped["subject"] || mapped["name"] || values.first
      mapped["period_scores"] = extract_period_scores(mapped, keys)
      mapped["raw_row"] = row.join(" | ")
      mapped
    end

    def extract_period_scores(mapped, keys)
      period_keys = keys.select { |key| key.match?(/\Aq\d+\z/) }
      return {} if period_keys.empty?

      period_keys.each_with_object({}) do |key, memo|
        memo[key] = mapped[key]
      end
    end

    def extract_school_year(lines)
      text = lines.join(" ")
      explicit = text.match(/\b(20\d{2})\s*[-\/]\s*(20\d{2})\b/)
      return "#{explicit[1]}-#{explicit[2]}" if explicit

      nil
    end

    def empty_result
      {
        "detected" => false,
        "source" => source_name,
        "school_year" => nil,
        "period_columns" => [],
        "header" => [],
        "rows" => [],
        "row_count" => 0
      }
    end
  end
end
