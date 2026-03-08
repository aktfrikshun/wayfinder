require "pdf/reader"
require "stringio"

module Attachments
  module Extractors
    class PdfTextExtractor < BaseExtractor
      def call
        text = attachment.metadata.to_h["native_pdf_text"].presence || extract_pdf_text.presence || read_attachment_as_text

        {
          method: "native",
          raw_extracted_text: text,
          normalized_text: normalize(text)
        }
      end

      private

      def extract_pdf_text
        data = download_primary_file
        return if data.blank?

        reader = PDF::Reader.new(StringIO.new(data))
        text = reader.pages.map(&:text).join("\n\n")
        normalize(text)
      rescue StandardError => e
        Rails.logger.warn("[Attachments::Extractors] PDF::Reader extraction failed: #{e.message}")
        nil
      end
    end
  end
end
