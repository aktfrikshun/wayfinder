module Artifacts
  module Extractors
    class BaseExtractor
      def initialize(artifact)
        @artifact = artifact
      end

      private

      attr_reader :artifact

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
