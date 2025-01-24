# frozen_string_literal: true

RSpec.describe 'Meilisearch::Client - Multiple Index Search' do
  before do
    client.create_index('books')
    client.create_index('movies').await
  end

  it 'does a custom search with two different indexes' do
    response = client.multi_search(queries: [
                                     { index_uid: 'books', q: 'prince' },
                                     { index_uid: 'movies', q: 'prince' }
                                   ])

    expect(response['results'].count).to eq(2)
    expect(response['results'][0]['estimatedTotalHits']).to eq(0)
    expect(response['results'][1]['estimatedTotalHits']).to eq(0)
  end

  context 'when passed a positional argument' do
    before { allow(Meilisearch::Utils).to receive(:soft_deprecate).and_return(nil) }

    it 'does a custom search with two different indexes' do
      response = client.multi_search([
                                       { index_uid: 'books', q: 'prince' },
                                       { index_uid: 'movies', q: 'prince' }
                                     ])

      expect(response['results'].count).to eq(2)
      expect(response['results'][0]['estimatedTotalHits']).to eq(0)
      expect(response['results'][1]['estimatedTotalHits']).to eq(0)
    end

    it 'warns about deprecation' do
      client.multi_search([
                            { index_uid: 'books', q: 'prince' },
                            { index_uid: 'movies', q: 'prince' }
                          ])

      expect(Meilisearch::Utils).to have_received(:soft_deprecate)
                                .with('multi_search([])', a_string_including('queries'))
    end
  end

  it 'does a federated search with two different indexes' do
    client.index('books').add_documents(
      [
        { id: 1, title: 'Harry Potter and the Philosophers Stone' },
        { id: 2, title: 'War and Peace' },
        { id: 5, title: 'Harry Potter and the Deathly Hallows' }
      ]
    )

    client.index('movies').add_documents(
      [
        { id: 1, title: 'Harry Potter and the Philosophers Stone' },
        { id: 2, title: 'Lord of the Rings' },
        { id: 4, title: 'Harry Potter and the Order of the Phoenix' }
      ]
    ).await

    response = client.multi_search(queries: [
                                     { index_uid: 'books', q: 'Harry Potter' },
                                     { index_uid: 'movies', q: 'Harry Potter' }
                                   ],
                                   federation: {
                                     limit: 3,
                                     offset: 1
                                   })

    expect(response['limit']).to eq(3)
    expect(response['offset']).to eq(1)

    hits = response['hits']
    expect(hits.size).to be 3
    expect(hits.first).to have_key('_federation')
  end

  describe 'searching multiple remotes' do
    it 'federated search searches multiple remotes' do
      client.update_experimental_features(network: true)
      proxy_client.update_experimental_features(network: true)

      client.update_network(
        self: 'ms0',
        remotes: {
          ms2: {
            url: PROXY_URL,
            search_api_key: MASTER_KEY
          }
        }
      )

      three_body_problem = { id: 1, title: 'The Three Body Problem' }
      the_dark_forest = { id: 2, title: 'The Dark Forest' }
      proxy_client.index('books').add_documents([three_body_problem, the_dark_forest]).await

      sherwood_forest = { id: 50, name: 'Sherwood Forest' }
      forbidden_forest = { id: 200, name: 'Forbidden Forest' }
      client.index('parks').add_documents([sherwood_forest, forbidden_forest]).await

      response = client.multi_search(
        federation: {},
        queries: [
          {
            q: 'Forest',
            index_uid: 'parks',
            federation_options: {
              remote: 'ms0'
            }
          },
          {
            q: 'Body',
            index_uid: 'books',
            federation_options: {
              remote: 'ms2'
            }
          }
        ]
      )

      resp = response['hits'].map { |hit| hit.slice('id', 'name', 'title').transform_keys(&:to_sym) }

      expect(resp).to include(three_body_problem, sherwood_forest, forbidden_forest)
      expect(resp).not_to include(the_dark_forest)
    rescue Meilisearch::CommunicationError
      pending('Please launch a second instance of Meilisearch to test network search, see spec_helper for addr config.')
      raise
    ensure
      client.update_network(self: nil, remotes: nil)
      client.delete_index('parks')
      proxy_client.delete_index('books')
    end
  end
end
