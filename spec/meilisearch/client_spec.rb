# frozen_string_literal: true

require './lib/meilisearch/client'

RSpec.describe MeiliSearch::Client do
  context 'standard client' do
    let(:client) { MeiliSearch::Client.new('http://localhost:8080', 'wrongApiKey') }

    it 'is healthy' do
      expect(client.is_healthy?).to be true
    end

    it 'has not access to /keys' do
      expect { client.keys }.to raise_error(MeiliSearch::ClientError)
    end
  end
end
