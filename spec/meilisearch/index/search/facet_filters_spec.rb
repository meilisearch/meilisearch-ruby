# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Search with facetFilters' do
  before(:all) do
    @documents = [
      { objectId: 123,  title: 'Pride and Prejudice',                    year: '1813', genre: 'romance' },
      { objectId: 456,  title: 'Le Petit Prince',                        year: '1943', genre: 'adventure' },
      { objectId: 1,    title: 'Alice In Wonderland',                    year: '1865', genre: 'adventure' },
      { objectId: 2,    title: 'Le Rouge et le Noir',                    year: '1830', genre: 'romance' },
      { objectId: 1344, title: 'The Hobbit',                             year: '1937', genre: 'adventure' },
      { objectId: 4,    title: 'Harry Potter and the Half-Blood Prince', year: '2005', genre: 'fantasy' },
      { objectId: 2056, title: 'Harry Potter and the Deathly Hallows',   year: '2007', genre: 'fantasy' },
      { objectId: 42,   title: 'The Hitchhiker\'s Guide to the Galaxy',  year: '1978' }
    ]
    client = MeiliSearch::Client.new($URL, $MASTER_KEY)
    clear_all_indexes(client)
    @index = client.create_index('books')
    response = @index.add_documents(@documents)
    @index.wait_for_pending_update(response['updateId'])
    response = @index.update_filterable_attributes(['genre', 'year'])
    @index.wait_for_pending_update(response['updateId'])
  end

  after(:all) do
    @index.delete
  end

  it 'does a custom search with facetFilters' do
    response = @index.search('prinec', facetFilters: ['genre: fantasy'])
    expect(response.keys).to contain_exactly(*$DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['nbHits']).to eq(1)
    expect(response['hits'][0]['objectId']).to eq(4)
  end

  it 'does a custom search with multiple facetFilters' do
    response = @index.search('potter', facetFilters: ['genre:fantasy', ['year:2005']])
    expect(response.keys).to contain_exactly(*$DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['nbHits']).to eq(1)
    expect(response['hits'][0]['objectId']).to eq(4)
  end

  it 'does a custom placeholder search with facetFilters' do
    response = @index.search('', facetFilters: ['genre:fantasy'])
    expect(response.keys).to contain_exactly(*$DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['nbHits']).to eq(2)
    expect(response['hits'][0]['objectId']).to eq(4)
    expect(response['hits'][1]['objectId']).to eq(2056)
  end

  it 'does a custom placeholder search with multiple facetFilters' do
    response = @index.search('', facetFilters: ['genre:adventure', ['year:1937']])
    expect(response.keys).to contain_exactly(*$DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['nbHits']).to eq(1)
    expect(response['hits'][0]['objectId']).to eq(1344)
  end
end
