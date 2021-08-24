# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Basic search' do
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

  it 'does a basic search in index' do
    response = @index.search('prince')
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*$DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits']).not_to be_empty
    expect(response['hits'].first).not_to have_key('_formatted')
  end

  it 'does a basic search with an empty query' do
    response = @index.search('')
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*$DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(@documents.count)
  end

  it 'does a basic search with a nil query' do
    response = @index.search(nil)
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*$DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(@documents.count)
    expect(response['hits'].first).not_to have_key('_formatted')
  end

  it 'does a basic search with an empty query and a custom ranking rule' do
    response = @index.update_ranking_rules([
                                             'typo',
                                             'words',
                                             'proximity',
                                             'attribute',
                                             'exactness',
                                             'asc(objectId)'
                                           ])
    @index.wait_for_pending_update(response['updateId'])
    response = @index.search('')
    expect(response['nbHits']).to eq(@documents.count)
    expect(response['hits'].first['objectId']).to eq(1)
  end

  it 'does a basic search with an integer query' do
    response = @index.search(1)
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*$DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(3)
    expect(response['hits'].first).not_to have_key('_formatted')
  end

  it 'does a phrase search' do
    response = @index.search('coco "harry"')
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*$DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(1)
    expect(response['hits'].first['objectId']).to eq(4)
    expect(response['hits'].first).not_to have_key('_formatted')
  end
end
