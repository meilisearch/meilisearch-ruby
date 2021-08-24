# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Search with offset' do
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

  it 'does a custom search with an offset set to 1' do
    response = @index.search('prince')
    response_with_offset = @index.search('prince', offset: 1)
    expect(response['hits'][1]).to eq(response_with_offset['hits'][0])
  end

  it 'does a placeholder search with an offset set to 3' do
    response = @index.search('')
    response_with_offset = @index.search('', offset: 3)
    expect(response['hits'][3]).to eq(response_with_offset['hits'][0])
  end

  it 'does a placeholder search with an offset set to 3 and custom ranking rules' do
    response = @index.update_ranking_rules(['asc(objectId)'])
    @index.wait_for_pending_update(response['updateId'])
    response = @index.search('')
    response_with_offset = @index.search('', offset: 3)
    expect(response['hits'].first['objectId']).to eq(1)
    expect(response['hits'][3]).to eq(response_with_offset['hits'][0])
    expect(response['hits'].last['objectId']).to eq(1344)
    expect(response_with_offset['hits'].last['objectId']).to eq(1344)
  end
end
