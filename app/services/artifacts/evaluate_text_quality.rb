module Artifacts
  class EvaluateTextQuality
    def self.call(text)
      new(text).call
    end

    def initialize(text)
      @text = text.to_s
    end

    def call
      cleaned = @text.gsub(/\s+/, " ").strip
      length_score = [cleaned.length / 1200.0, 1.0].min
      alpha_ratio = if cleaned.empty?
        0.0
      else
        cleaned.scan(/[A-Za-z]/).length.to_f / cleaned.length
      end
      noise_ratio = if cleaned.empty?
        1.0
      else
        cleaned.scan(/[^\w\s,.!?;:'"()\-]/).length.to_f / cleaned.length
      end

      score = (0.55 * length_score) + (0.35 * alpha_ratio) + (0.10 * (1.0 - noise_ratio))
      score = score.clamp(0.0, 1.0)

      {
        text_quality_score: score.round(3),
        too_short: cleaned.length < 80,
        too_noisy: noise_ratio > 0.25,
        likely_needs_ocr: cleaned.blank? || cleaned.length < 80 || alpha_ratio < 0.45
      }
    end
  end
end
