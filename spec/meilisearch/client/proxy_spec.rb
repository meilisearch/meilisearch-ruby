# frozen_string_literal: true

describe 'Meilisearch::Client - proxy search' do
  # Not sure yet what the default return from remotes is
  # It will probably be { uid: 'default', url: client_url, ...}
  let(:default_remotes) { nil }

  let(:sample_remote) do
    {
      uid: 'ms-2',
      url: PROXY_URL,
      search_api_key: MASTER_KEY
    }
  end

  # Experimental feature must be enabled before these specs
  # but the PR for that is yet to be merged
  describe '#self' do
    it 'returns the name of the current shard' do
      # from what I can see default shard name remains to be documented
      # following the naming of embedders, I guessed 'default'
      expect(client.self).to eq 'default'
    end
  end

  describe '#update_self' do
    it 'switches to a different shard' do
      client.add_remote(
        uid: 'ms-2',
        url: 'ms-gaunt-hovel.meilisearch.com:7700',
        search_api_key: 'masterKey'
      )

      # I'm unaware if this is supposed to return a task yet
      # I imagine it's just updating a string, but there could
      #   be things the engine needs to do upon this value being set
      client.update_self('ms-2')
      expect(client.self).to eq 'ms-2'
    ensure
      client.delete_remote('ms-2')
    end
  end

  describe '#remotes' do
    it 'lists all remotes' do
      expect(client.remotes).to eq(default_remotes)
    end
  end

  describe '#remote' do
    it 'returns a specific remote' do
      client.add_remote(sample_remote)

      expect(client.remote('ms-2')).to include(*sample_remote.values)
    ensure
      client.delete_remote('ms-2')
    end
  end

  describe '#add_remote' do
    it 'adds new shards' do
      client.add_remote(sample_remote)

      expect(client.remotes).to include(sample_remote)
    ensure
      client.delete_remote('ms-2')
    end
  end

  describe '#update_remote' do
    it 'edits an existing shard entry' do
      client.add_remote(sample_remote)

      edit = { search_api_key: 'plaintextSecret' }
      client.update_remote('ms-2', edit)

      expected = sample_remote.merge(edit)
      actual = client.remote('ms-2')

      expect(actual).to eq(expected)
    ensure
      client.delete_remote('ms-2')
    end
  end

  describe '#delete_remote' do
    it 'deletes a shard from uid' do
      client.add_remote(sample_remote)
      expect(client.remotes).to include(sample_remote)

      client.delete_remote('ms-2')
      expect(client.remotes).to eq(default_remotes)
    end
  end

  describe 'searching multiple remotes' do
    # this of course means we need to support federated search,
    # which has not been merged yet.
    it 'federated search searches multiple remotes' do
      three_body_problem = { id: 1, title: 'The Three Body Problem' }
      the_dark_forest = { id: 2, title: 'The Dark Forest' }
      proxy_client.index('books').add_documents([three_body_problem, the_dark_forest])

      sherwood_forest = { id: 50, name: 'Sherwood Forest' }
      forbidden_forest = { id: 200, name: 'Forbidden Forest' }
      client.index('parks').add_documents([sherwood_forest, forbidden_forest])

      client.add_remote(sample_remote)

      response = client.multi_search(
        federation: {},
        queries: [
          {
            q: 'Forest',
            index_uid: 'parks'
          },
          {
            q: 'Body',
            index_uid: 'books',
            remote: 'ms-2'
          }
        ]
      )

      expect(response['hits']).to include(three_body_problem, sherwood_forest, forbidden_forest)
      expect(response['hits']).not_to include(the_dark_forest)
    end
  end
end
