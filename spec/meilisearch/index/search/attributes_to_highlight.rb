# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Search with highlight' do
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
    @index.add_documents(@documents)
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

  it 'does a custom search with highlight' do
    response = @index.search('the', attributesToHighlight: ['*'])
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*default_search_response_keys)
    expect(response['hits'].count).to eq(3)
    expect(response['hits'].first).to have_key('_formatted')
  end

  it 'does a custom placeholder search with attributes to highlight' do
    response = @index.search('', attributesToHighlight: ['*'])
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*default_search_response_keys)
    expect(response['hits'].count).to eq(7)
    expect(response['hits'].first).to have_key('_formatted')
  end

  it 'does a custom placeholder search (nil) with attributes to highlight' do
    response = @index.search(nil, attributesToHighlight: ['*'])
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*default_search_response_keys)
    expect(response['hits'].count).to eq(@documents.count)
    expect(response['hits'].first).to have_key('_formatted')
  end
end
