# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Errors' do
  describe 'MeiliSearch::Error' do
    it 'catches all other errors' do
      expect(MeiliSearch::TimeoutError.ancestors).to include(MeiliSearch::Error)
      expect(MeiliSearch::CommunicationError.ancestors).to include(MeiliSearch::Error)
      expect(MeiliSearch::ApiError.ancestors).to include(MeiliSearch::Error)
      expect(MeiliSearch::TenantToken::InvalidApiKey.ancestors).to include(MeiliSearch::Error)
      expect(MeiliSearch::TenantToken::InvalidSearchRules.ancestors).to include(MeiliSearch::Error)
      expect(MeiliSearch::TenantToken::ExpireOrInvalidSignature.ancestors).to include(MeiliSearch::Error)
    end
  end

  context 'when request takes to long to answer' do
    it 'raises MeiliSearch::TimeoutError' do
      timed_client = MeiliSearch::Client.new(URL, MASTER_KEY, { timeout: 0.000001 })

      expect do
        timed_client.version
      end.to raise_error(MeiliSearch::TimeoutError)
    end
  end

  context 'when body is too large' do
    let(:index) { client.index('movies') }

    it 'raises MeiliSearch::CommunicationError' do
      allow(index.class).to receive(:post).and_raise(Errno::EPIPE)

      expect do
        index.add_documents([{ id: 1, text: 'my_text' }])
      end.to raise_error(MeiliSearch::CommunicationError)
    end
  end
end
