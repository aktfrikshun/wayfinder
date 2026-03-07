module Artifacts
  module Extractors
    class BaseExtractor
      def initialize(artifact)
        @artifact = artifact
      end

      private

      attr_reader :artifact

      def primary_attachment
        @primary_attachment ||= artifact.primary_file
      end

      def download_primary_file
        return unless primary_attachment&.blob

        primary_attachment.blob.download
      rescue StandardError => e
        Rails.logger.warn("[Artifacts::Extractors] download_primary_file failed: #{e.message}")
        nil
      end

      def read_attachment_as_text
        data = download_primary_file
        return if data.blank?

        text = data.force_encoding("UTF-8")
        return text if text.valid_encoding?

        text.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      rescue StandardError => e
        Rails.logger.warn("[Artifacts::Extractors] read_attachment_as_text failed: #{e.message}")
        nil
      end

      def normalize(text)
        text.to_s
          .gsub(/\r\n?/, "\n")
          .gsub(/[\t\f\v]/, " ")
          .gsub(/\n{3,}/, "\n\n")
          .gsub(/[ ]{2,}/, " ")
          .strip
      end
    end
  end
end
