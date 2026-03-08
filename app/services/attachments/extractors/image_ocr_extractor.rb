module Attachments
  module Extractors
    class ImageOcrExtractor < BaseExtractor
      def call
        text = attachment.metadata.to_h["ocr_text"].presence || attachment.body_text

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
