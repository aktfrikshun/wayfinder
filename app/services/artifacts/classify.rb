module Artifacts
  class Classify
    KEYWORDS = {
      "assignment" => %w[due homework assignment submit submittion classroom],
      "report_card" => %w[report card trimester grade progress],
      "assessment_result" => %w[assessment benchmark score percentile],
      "health_record" => %w[doctor clinic diagnosis medication visit],
      "social_emotional_signal" => %w[anxiety stress overwhelmed behavior concern],
      "administrative_document" => %w[permission slip policy enrollment registration]
    }.freeze

    def self.call(artifact)
      new(artifact).call
    end

    def initialize(artifact)
      @artifact = artifact
    end

    def call
      artifact.update!(processing_state: "classifying")

      text = [artifact.display_title, artifact.normalized_text, artifact.subject].compact.join(" ").downcase
      matched_category, matched_terms = infer_category(text)

      artifact.update!(
        system_category: matched_category,
        category_confidence: confidence_for(matched_terms),
        tags: matched_terms.uniq,
        extracted_payload: artifact.extracted_payload.to_h.merge("category_rationale" => category_rationale(matched_category, matched_terms))
      )

      artifact
    end

    private

    attr_reader :artifact

    def infer_category(text)
      best = ["school_communication", []]

      KEYWORDS.each do |category, terms|
        matched = terms.select { |term| text.include?(term) }
        best = [category, matched] if matched.length > best[1].length
      end

      best
    end

    def confidence_for(matched_terms)
      return 0.4 if matched_terms.empty?

      [0.55 + (matched_terms.length * 0.08), 0.95].min
    end

    def category_rationale(category, terms)
      return "Defaulted to school_communication due to limited classification signals." if terms.empty?

      "Matched #{terms.join(', ')} suggesting #{category}."
    end
  end
end
