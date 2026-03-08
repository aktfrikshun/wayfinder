module Attachments
  module Extractors
    class DocxTextExtractor < BaseExtractor
      def call
        text = attachment.metadata.to_h["document_text"].presence ||
               attachment.body_text.presence ||
               read_attachment_as_text

        {
          method: "native",
          raw_extracted_text: text,
          normalized_text: normalize(text)
        }
      end
    end
  end
end
