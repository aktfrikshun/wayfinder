module Attachments
  class ExtractText
    def self.call(attachment)
      new(attachment).call
    end

    def initialize(attachment)
      @attachment = attachment
    end

    def call
      attachment.update!(processing_state: "extracting_text")

      primary = primary_extractor.new(attachment).call
      quality = Attachments::EvaluateTextQuality.call(primary[:normalized_text])

      needs_ocr = ocr_needed?(quality)
      fallback = needs_ocr ? Extractors::ImageOcrExtractor.new(attachment).call : nil

      update_attrs = {
        text_extraction_method: extraction_method(primary, fallback),
        raw_extracted_text: fallback&.dig(:raw_extracted_text) || primary[:raw_extracted_text],
        ocr_text: fallback&.dig(:ocr_text),
        normalized_text: fallback&.dig(:normalized_text) || primary[:normalized_text],
        text_quality_score: quality[:text_quality_score],
        metadata: attachment.metadata.to_h.merge(
          "text_quality_flags" => quality.except(:text_quality_score),
          "ocr_fallback_used" => fallback.present?
        )
      }

      attachment.update!(update_attrs)
      attachment
    end

    private

    attr_reader :attachment

    def primary_extractor
      case attachment.content_type
      when "message" then Extractors::EmailTextExtractor
      when "pdf" then Extractors::PdfTextExtractor
      when "document" then Extractors::DocxTextExtractor
      when "image" then Extractors::ImageOcrExtractor
      else Extractors::FallbackExtractor
      end
    end

    def ocr_needed?(quality)
      return true if attachment.image?
      return true if attachment.metadata.to_h["scanned"] == true

      attachment.pdf? && quality[:likely_needs_ocr]
    end

    def extraction_method(primary, fallback)
      return "none" if primary[:raw_extracted_text].blank? && fallback.blank?
      return "native_plus_ocr" if fallback.present? && primary[:method] == "native"

      fallback&.dig(:method) || primary[:method]
    end
  end
end
