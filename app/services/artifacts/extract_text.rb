module Artifacts
  class ExtractText
    def self.call(artifact)
      new(artifact).call
    end

    def initialize(artifact)
      @artifact = artifact
    end

    def call
      artifact.update!(processing_state: "extracting_text")

      primary = primary_extractor.new(artifact).call
      quality = Artifacts::EvaluateTextQuality.call(primary[:normalized_text])

      needs_ocr = ocr_needed?(quality)
      fallback = needs_ocr ? Extractors::ImageOcrExtractor.new(artifact).call : nil

      update_attrs = {
        text_extraction_method: extraction_method(primary, fallback),
        raw_extracted_text: fallback&.dig(:raw_extracted_text) || primary[:raw_extracted_text],
        ocr_text: fallback&.dig(:ocr_text),
        normalized_text: fallback&.dig(:normalized_text) || primary[:normalized_text],
        text_quality_score: quality[:text_quality_score],
        metadata: artifact.metadata.to_h.merge(
          "text_quality_flags" => quality.except(:text_quality_score),
          "ocr_fallback_used" => fallback.present?
        )
      }

      artifact.update!(update_attrs)
      artifact
    end

    private

    attr_reader :artifact

    def primary_extractor
      case artifact.content_type
      when "message" then Extractors::EmailTextExtractor
      when "pdf" then Extractors::PdfTextExtractor
      when "document" then Extractors::DocxTextExtractor
      when "image" then Extractors::ImageOcrExtractor
      else Extractors::FallbackExtractor
      end
    end

    def ocr_needed?(quality)
      return true if artifact.image?
      return true if artifact.metadata.to_h["scanned"] == true

      artifact.pdf? && quality[:likely_needs_ocr]
    end

    def extraction_method(primary, fallback)
      return "none" if primary[:raw_extracted_text].blank? && fallback.blank?
      return "native_plus_ocr" if fallback.present? && primary[:method] == "native"

      fallback&.dig(:method) || primary[:method]
    end
  end
end
