require "open3"
require "tempfile"
require "tmpdir"

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

          return ocr_from_pdf(file.path) if ext.downcase == ".pdf"

          ocr_from_image_path(file.path)
        end
      rescue StandardError => e
        Rails.logger.warn("[Attachments::Extractors] OCR extraction failed: #{e.message}")
        nil
      end

      def ocr_from_pdf(pdf_path)
        if command_available?("pdftoppm")
          Dir.mktmpdir("wayfinder-pdf-ocr") do |dir|
            prefix = File.join(dir, "page")
            _stdout, stderr, status = Open3.capture3("pdftoppm", "-png", "-f", "1", "-l", "3", pdf_path, prefix)
            unless status.success?
              Rails.logger.warn("[Attachments::Extractors] pdftoppm failed: #{stderr}")
              return nil
            end

            texts = Dir[File.join(dir, "page-*.png")].sort.filter_map { |img| ocr_from_image_path(img) }
            return normalize(texts.join("\n\n")) if texts.any?
          end
        end

        ocr_from_image_path(pdf_path)
      end

      def ocr_from_image_path(path)
        stdout, stderr, status = Open3.capture3("tesseract", path, "stdout")
        return normalize(stdout) if status.success?

        Rails.logger.warn("[Attachments::Extractors] tesseract failed: #{stderr}")
        nil
      end

      def command_available?(name)
        _stdout, _stderr, status = Open3.capture3("sh", "-lc", "command -v #{name}")
        status.success?
      end
    end
  end
end
