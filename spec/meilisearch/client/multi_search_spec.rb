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
end
