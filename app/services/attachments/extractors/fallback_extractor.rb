module Attachments
  module Extractors
    class FallbackExtractor < BaseExtractor
      def call
        text = attachment.body_text.presence || ActionView::Base.full_sanitizer.sanitize(attachment.body_html.to_s)

        {
          method: text.present? ? "native" : "none",
          raw_extracted_text: text,
          normalized_text: normalize(text)
        }
      end
    end
  end
end
