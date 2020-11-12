# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Search with attributes to retrieve' do
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

  it 'does a custom search with one attributesToRetrieve' do
    response = @index.search('the', attributesToRetrieve: ['title'])
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*default_search_response_keys)
    expect(response['hits'].count).to eq(3)
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).not_to have_key('objectId')
    expect(response['hits'].first).not_to have_key('genre')
  end

  it 'does a custom search with multiple attributesToRetrieve' do
    response = @index.search('the', attributesToRetrieve: ['title', 'genre'])
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*default_search_response_keys)
    expect(response['hits'].count).to eq(3)
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).not_to have_key('objectId')
    expect(response['hits'].first).to have_key('genre')
  end

  it 'does a custom placeholder search with attributesToRetrieve as string' do
    response = @index.search('', attributesToRetrieve: ['title'])
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*default_search_response_keys)
    expect(response['hits'].count).to eq(@documents.count)
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).not_to have_key('objectId')
    expect(response['hits'].first).not_to have_key('genre')
  end

  it 'does a custom placeholder search with attributesToRetrieve as an array of string' do
    response = @index.search('', attributesToRetrieve: ['title', 'genre'])
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*default_search_response_keys)
    expect(response['hits'].count).to eq(@documents.count)
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).not_to have_key('objectId')
    expect(response['hits'].first).to have_key('genre')
  end
end
