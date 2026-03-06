module AI
  class ExtractArtifact
    def self.call(artifact, client: OpenAIClient.new)
      new(artifact, client: client).call
    end

    def initialize(artifact, client: OpenAIClient.new)
      @artifact = artifact
      @client = client
    end

    def call
      extractor.call
    end

    private

    attr_reader :artifact, :client

    def extractor
      return ExtractParentNoteArtifact.new(artifact: artifact, client: client) if artifact.parent_note?
      return ExtractImageArtifact.new(artifact: artifact, client: client) if artifact.image?
      return ExtractDocumentArtifact.new(artifact: artifact, client: client) if artifact.pdf? || artifact.document?

      ExtractEmailArtifact.new(artifact: artifact, client: client)
    end
  end
end
