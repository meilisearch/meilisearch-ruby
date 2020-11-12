# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Cropped search' do
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

  it 'does a custom search with attributes to crop' do
    response = @index.search('guide', { attributesToCrop: ['title'], cropLength: 2 })
    expect(response['hits'].first).to have_key('_formatted')
    expect(response['hits'].first['_formatted']['title']).to eq('s Guide')
  end
  it 'does a custom placehodler search with attributes to crop' do
    response = @index.search('', { attributesToCrop: ['title'], cropLength: 1 })
    expect(response['hits'].first).to have_key('_formatted')
    expect(response['hits'].first['title']).to eq(@documents.first[:title])
    expect(response['hits'].first['_formatted']['title']).not_to eq(@documents.first[:title])
  end
end
