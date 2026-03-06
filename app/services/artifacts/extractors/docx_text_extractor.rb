module Artifacts
  module Extractors
    class DocxTextExtractor < BaseExtractor
      def call
        text = artifact.metadata.to_h["document_text"].presence || artifact.body_text

        {
          method: "native",
          raw_extracted_text: text,
          normalized_text: normalize(text)
        }
      end
    end
  end
end
