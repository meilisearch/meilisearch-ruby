# frozen_string_literal: true

require './lib/meilisearch/client'

RSpec.describe MeiliSearch::Client do
  context 'Client with wrong master API key' do
    let(:client) { MeiliSearch::Client.new($URL, 'wrongApiKey') }

    it 'is healthy' do
      expect(client.is_healthy?).to be true
    end

    it 'has no access to others routes' do
      expect { client.keys }.to raise_error(MeiliSearch::HTTPError)
    end
  end

  context 'Client with right master API key' do
    let(:client) { MeiliSearch::Client.new($URL, $API_KEY) }

    it 'is healthy' do
      expect(client.is_healthy?).to be true
    end

    it 'has access to others routes' do
      expect(client.keys).to be_empty
    end
  end

  context 'Client with bad url' do
    let(:client) { MeiliSearch::Client.new('nope') }

    it 'is not healthy' do
      expect(client.is_healthy?).to be false
    end
  end

  context 'Client with no master API key' do
    let(:client) { MeiliSearch::Client.new($URL) }

    it 'is healthy' do
      expect(client.is_healthy?).to be true
    end

    it 'can access to health route' do
      expect(client.health).to be_nil
    end

    it 'cannot access to keys route' do
      expect { client.keys }.to raise_error(MeiliSearch::HTTPError)
    end
  end
end
