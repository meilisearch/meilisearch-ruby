# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Multi-paramaters search' do
  before(:all) do
    @documents = [
      { objectId: 123,  title: 'Pride and Prejudice',                    genre: 'romance' },
      { objectId: 456,  title: 'Le Petit Prince',                        genre: 'adventure' },
      { objectId: 1,    title: 'Alice In Wonderland',                    genre: 'adventure' },
      { objectId: 2,    title: 'Le Rouge et le Noir',                    genre: 'romance' },
      { objectId: 1344, title: 'The Hobbit',                             genre: 'adventure' },
      { objectId: 4,    title: 'Harry Potter and the Half-Blood Prince', genre: 'fantasy' },
      { objectId: 42,   title: 'The Hitchhiker\'s Guide to the Galaxy' }
    ]
    client = MeiliSearch::Client.new($URL, $MASTER_KEY)
    clear_all_indexes(client)
    @index = client.create_index('books')
    response = @index.add_documents(@documents)
    @index.wait_for_pending_update(response['updateId'])
  end

  after(:all) do
    @index.delete
  end

  it 'does a custom search with attributes to crop, filters and attributes to highlight' do
    response = @index.search('prince',
                             {
                               attributesToCrop: ['title'],
                               cropLength: 2,
                               filters: 'genre = adventure',
                               attributesToHighlight: ['title']
                             })
    expect(response['hits'].count).to be(1)
    expect(response['hits'].first).to have_key('_formatted')
    expect(response['hits'].first['_formatted']['title']).to eq('<em>Prince</em>')
  end

  it 'does a custom search with attributesToRetrieve and a limit' do
    response = @index.search('the', attributesToRetrieve: ['title', 'genre'], limit: 2)
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*$DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(2)
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).not_to have_key('objectId')
    expect(response['hits'].first).to have_key('genre')
  end

  it 'does a custom placeholder search with filters and offset' do
    response = @index.search('', { filters: 'genre = adventure', offset: 2 })
    expect(response['hits'].count).to eq(1)
  end

  it 'does a custom search with limit and attributes to highlight' do
    response = @index.search('the', { limit: 1, attributesToHighlight: ['*'] })
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*$DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(1)
    expect(response['hits'].first).to have_key('_formatted')
  end

  it 'does a custom search with facetFilters, attributesToRetrieve and attributesToHighlight' do
    response = @index.update_attributes_for_faceting(['genre'])
    @index.wait_for_pending_update(response['updateId'])
    response = @index.search('prinec',
                             {
                               facetFilters: ['genre: fantasy'],
                               attributesToRetrieve: ['title'],
                               attributesToHighlight: ['*']
                             })
    expect(response.keys).to contain_exactly(*$DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['nbHits']).to eq(1)
    expect(response['hits'].first).to have_key('_formatted')
    expect(response['hits'].first).not_to have_key('objectId')
    expect(response['hits'].first).not_to have_key('genre')
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first['_formatted']['title']).to eq('Harry Potter and the Half-Blood <em>Prince</em>')
  end

  it 'does a custom search with facetsDistribution and limit' do
    response = @index.update_attributes_for_faceting(['genre'])
    @index.wait_for_pending_update(response['updateId'])
    response = @index.search('prinec', facetsDistribution: ['genre'], limit: 1)
    expect(response.keys).to contain_exactly(
      *$DEFAULT_SEARCH_RESPONSE_KEYS,
      'facetsDistribution',
      'exhaustiveFacetsCount'
    )
    expect(response['exhaustiveFacetsCount']).to be true
    expect(response['nbHits']).to eq(2)
    expect(response['hits'].count).to eq(1)
    expect(response['facetsDistribution'].keys).to contain_exactly('genre')
    expect(response['facetsDistribution']['genre'].keys).to contain_exactly('romance', 'adventure', 'fantasy')
    expect(response['facetsDistribution']['genre']['romance']).to eq(0)
    expect(response['facetsDistribution']['genre']['adventure']).to eq(1)
    expect(response['facetsDistribution']['genre']['fantasy']).to eq(1)
  end
end
