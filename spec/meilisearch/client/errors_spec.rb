# frozen_string_literal: true

RSpec.describe 'Meilisearch::Client - Errors' do
  describe 'Meilisearch::Error' do
    it 'catches all other errors' do
      expect(Meilisearch::TimeoutError.ancestors).to include(Meilisearch::Error)
      expect(Meilisearch::CommunicationError.ancestors).to include(Meilisearch::Error)
      expect(Meilisearch::ApiError.ancestors).to include(Meilisearch::Error)
      expect(Meilisearch::TenantToken::InvalidApiKey.ancestors).to include(Meilisearch::Error)
      expect(Meilisearch::TenantToken::InvalidSearchRules.ancestors).to include(Meilisearch::Error)
      expect(Meilisearch::TenantToken::ExpireOrInvalidSignature.ancestors).to include(Meilisearch::Error)
    end
  end

  context 'when request takes too long to answer' do
    it 'raises Meilisearch::TimeoutError' do
      timed_client = Meilisearch::Client.new(URL, MASTER_KEY, { timeout: 0.000001 })

      expect do
        timed_client.version
      end.to raise_error(Meilisearch::TimeoutError)
    end
  end

  context 'when connection is broken' do
    let(:index) { client.index('movies') }

    it 'raises Meilisearch::CommunicationError on EPIPE' do
      http_client = index.instance_variable_get(:@http_client)
      allow(http_client).to receive(:post).and_raise(Errno::EPIPE)

      expect do
        index.add_documents([{ id: 1, text: 'my_text' }])
      end.to raise_error(Meilisearch::CommunicationError)
    end
  end

  context 'when document id is invalid' do
    it 'raises Meilisearch::InvalidDocumentId' do
      expect do
        client.index('movies').delete_document(nil)
      end.to raise_error(Meilisearch::InvalidDocumentId)
    end
  end

  context 'when url is missing protocol' do
    it 'throws a CommunicationError with a useful message' do
      expect do
        c = Meilisearch::Client.new('localhost:7700')
        c.health
      end.to raise_error(Meilisearch::CommunicationError).with_message(/protocol/)
    end
  end

  context 'when url is malformed' do
    it 'throws a CommunicationError' do
      expect do
        c = Meilisearch::Client.new('http://localh ost:7700')
        c.health
      end.to raise_error(Meilisearch::CommunicationError)
    end
  end
end
