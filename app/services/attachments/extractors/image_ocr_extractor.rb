require "open3"
require "tempfile"

module Attachments
  module Extractors
    class ImageOcrExtractor < BaseExtractor
      def call
        text = attachment.metadata.to_h["ocr_text"].presence ||
               perform_ocr_from_primary_file.presence ||
               attachment.body_text

        {
          method: "ocr",
          ocr_text: text,
          raw_extracted_text: text,
          normalized_text: normalize(text)
        }
      end

      private

      def perform_ocr_from_primary_file
        return if primary_attachment&.blob.blank?

        source_data = download_primary_file
        return if source_data.blank?

        ext = File.extname(primary_attachment.filename.to_s).presence || ".img"

        Tempfile.create(["wayfinder-ocr-", ext]) do |file|
          file.binmode
          file.write(source_data)
          file.flush

          stdout, stderr, status = Open3.capture3("tesseract", file.path, "stdout")
          return normalize(stdout) if status.success?

          Rails.logger.warn("[Attachments::Extractors] tesseract failed: #{stderr}")
          nil
        end
      rescue StandardError => e
        Rails.logger.warn("[Attachments::Extractors] OCR extraction failed: #{e.message}")
        nil
      end
    end
  end
end
