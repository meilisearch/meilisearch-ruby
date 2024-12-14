# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Multiple Index Search' do
  before do
    client.create_index('books')
    client.create_index('movies').await
  end

  it 'does a custom search with two different indexes' do
    response = client.multi_search([
                                     { index_uid: 'books', q: 'prince' },
                                     { index_uid: 'movies', q: 'prince' }
                                   ])

    expect(response['results'].count).to eq(2)
    expect(response['results'][0]['estimatedTotalHits']).to eq(0)
    expect(response['results'][1]['estimatedTotalHits']).to eq(0)
  end

  it 'does a federated search with two different indexes' do
    client.index('books').add_documents(
      [
        { id: 1, title: 'Harry Potter and the Philosophers Stone' },
        { id: 2, title: 'War and Peace' }
      ]
    )

    client.index('movies').add_documents(
      [
        { id: 1, title: 'Harry Potter and the Philosophers Stone' },
        { id: 2, title: 'Lord of the Rings' }
      ]
    ).await

    response = client.multi_search([
                                     { index_uid: 'books', q: 'Harry Potter' },
                                     { index_uid: 'movies', q: 'Harry Potter' }
                                   ],
                                   {
                                     limit: 20,
                                     offset: 0
                                   })

    expect(response).to have_key('hits')
    expect(response['hits'].first).to have_key('_federation')
    expect(response['hits'].first['_federation']).to have_key('indexUid')
    expect(response).to have_key('estimatedTotalHits')
    expect(response).not_to have_key('results')
    expect(response['limit']).to eq(20)
    expect(response['offset']).to eq(0)
  end
end
