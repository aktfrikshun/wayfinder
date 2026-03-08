module AI
  class ExtractAttachment
    def self.call(attachment, client: OpenAIClient.new)
      new(attachment, client: client).call
    end

    def initialize(attachment, client: OpenAIClient.new)
      @attachment = attachment
      @client = client
    end

    def call
      extractor.call
    end

    private

    attr_reader :attachment, :client

    def extractor
      return ExtractParentNoteAttachment.new(attachment: attachment, client: client) if attachment.parent_note?
      return ExtractImageAttachment.new(attachment: attachment, client: client) if attachment.image?
      return ExtractDocumentAttachment.new(attachment: attachment, client: client) if attachment.pdf? || attachment.document?

      ExtractEmailAttachment.new(attachment: attachment, client: client)
    end
  end
end
