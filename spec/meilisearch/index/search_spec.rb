# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Search' do
  before(:all) do
    documents = [
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
    @index.add_documents(documents)
    sleep(0.1)
  end

  after(:all) do
    @index.delete
  end

  let(:default_search_response_keys) do
    [
      'hits',
      'offset',
      'limit',
      'nbHits',
      'exhaustiveNbHits',
      'processingTimeMs',
      'query'
    ]
  end

  it 'does a basic search in index' do
    response = @index.search('prince')
    expect(response).to be_a(Hash)
    expect(response).to have_key('hits')
    expect(response['hits']).not_to be_empty
    expect(response.keys).to contain_exactly(*default_search_response_keys)
    expect(response['hits'].first).not_to have_key('_formatted')
  end

  it 'does a custom search with limit' do
    response = @index.search('the', limit: 1)
    expect(response).to be_a(Hash)
    expect(response).to have_key('hits')
    expect(response.keys).to contain_exactly(*default_search_response_keys)
    expect(response['hits'].count).to eq(1)
    expect(response['hits'].first).not_to have_key('_formatted')
  end

  it 'does a custom search with highlight' do
    response = @index.search('the', attributesToHighlight: '*')
    expect(response).to be_a(Hash)
    expect(response).to have_key('hits')
    expect(response.keys).to contain_exactly(*default_search_response_keys)
    expect(response['hits'].count).to eq(3)
    expect(response['hits'].first).to have_key('_formatted')
  end

  it 'does a custom search with attributesToRetrieve as string' do
    response = @index.search('the', attributesToRetrieve: 'title')
    expect(response).to be_a(Hash)
    expect(response).to have_key('hits')
    expect(response.keys).to contain_exactly(*default_search_response_keys)
    expect(response['hits'].count).to eq(3)
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).not_to have_key('objectId')
    expect(response['hits'].first).not_to have_key('genre')
  end

  it 'does a custom search with attributesToRetrieve as an array of string' do
    response = @index.search('the', attributesToRetrieve: ['title', 'genre'])
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*default_search_response_keys)
    expect(response['hits'].count).to eq(3)
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).not_to have_key('objectId')
    expect(response['hits'].first).to have_key('genre')
  end

  it 'does a custom search with facetsDistribution' do
    @index.update_attributes_for_faceting(['genre'])
    sleep(0.1)
    response = @index.search('prinec', facetsDistribution: ['genre'])
    expect(response.keys).to contain_exactly(
      *default_search_response_keys,
      'facetsDistribution',
      'exhaustiveFacetsCount'
    )
    expect(response['exhaustiveFacetsCount']).to be true
    expect(response['nbHits']).to eq(2)
    expect(response['facetsDistribution'].keys).to contain_exactly('genre')
    expect(response['facetsDistribution']['genre'].keys).to contain_exactly('romance', 'adventure', 'fantasy')
    expect(response['facetsDistribution']['genre']['romance']).to eq(0)
    expect(response['facetsDistribution']['genre']['adventure']).to eq(1)
    expect(response['facetsDistribution']['genre']['fantasy']).to eq(1)
  end

  it 'does a custom search with facetFilters' do
    @index.update_attributes_for_faceting(['genre'])
    sleep(0.1)
    response = @index.search('prinec', facetFilters: ['genre: fantasy'])
    expect(response.keys).to contain_exactly(*default_search_response_keys)
    expect(response['nbHits']).to eq(1)
    expect(response['hits'][0]['objectId']).to eq(4)
  end
end
