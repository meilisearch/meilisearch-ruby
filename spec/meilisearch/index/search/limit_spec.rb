# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Search with limit' do
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

  it 'does a custom search with limit' do
    response = @index.search('the', limit: 1)
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*$DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(1)
    expect(response['hits'].first).not_to have_key('_formatted')
  end

  it 'does a custom placeholder search with limit' do
    response = @index.search('', limit: 2)
    expect(response['hits'].count).to be(2)
    expect(response['hits'].first['objectId']).to eq(123)
    expect(response['hits'].last['objectId']).to eq(456)
    expect(response['hits'].first).not_to have_key('_formatted')
  end
end
