module Artifacts
  module Extractors
    class ImageOcrExtractor < BaseExtractor
      def call
        text = artifact.metadata.to_h["ocr_text"].presence || artifact.body_text

        {
          method: "ocr",
          ocr_text: text,
          raw_extracted_text: text,
          normalized_text: normalize(text)
        }
      end
    end
  end
end
