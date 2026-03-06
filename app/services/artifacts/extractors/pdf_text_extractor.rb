module Artifacts
  module Extractors
    class PdfTextExtractor < BaseExtractor
      def call
        text = artifact.metadata.to_h["native_pdf_text"].presence

        {
          method: "native",
          raw_extracted_text: text,
          normalized_text: normalize(text)
        }
      end
    end
  end
end
