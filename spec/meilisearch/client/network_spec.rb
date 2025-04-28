# frozen_string_literal: true

describe 'Meilisearch::Client - Network' do
  before do
    client.update_experimental_features(network: true)
  end

  let(:default_network) do
    {
      'self' => nil,
      'remotes' => {}
    }
  end

  let(:sample_remote) do
    {
      ms1: {
        url: 'http://localhost',
        search_api_key: 'masterKey'
      }
    }
  end

  describe '#network' do
    it 'returns the sharding configuration' do
      expect(client.network).to eq default_network
    end
  end

  describe '#update_network' do
    it 'updates the sharding configuration' do
      new_network = {
        self: 'ms0',
        remotes: sample_remote
      }

      client.update_network(new_network)
      expect(client.network).to eq(Meilisearch::Utils.transform_attributes(new_network))

      client.update_network({ remotes: nil, self: nil })
      expect(client.network).to eq default_network
    end
  end
end
