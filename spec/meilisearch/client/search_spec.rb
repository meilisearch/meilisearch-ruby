# frozen_string_literal: true

require './lib/meilisearch/client'

RSpec.describe MeiliSearch::Client::Search do
  before(:all) do
    schema = {
      objectId: [:displayed, :indexed, :identifier],
      title: [:displayed, :indexed]
    }
    documents = [
      { objectId: 123,  title: 'Pride and Prejudice' },
      { objectId: 456,  title: 'Le Petit Prince' },
      { objectId: 1,    title: 'Alice In Wonderland' },
      { objectId: 1344, title: 'The Hobbit' },
      { objectId: 4,    title: 'Harry Potter and the Half-Blood Prince' },
      { objectId: 42,   title: 'The Hitchhiker\'s Guide to the Galaxy' }
    ]
    @client = MeiliSearch::Client.new('http://localhost:8080', 'apiKey')
    response = @client.create_index('index_name', schema)
    @index_uid = response['uid']
    @client.add_documents(@index_uid, documents)
    sleep(0.1)
  end

  after(:all) do
    @client.delete_index(@index_uid)
  end

  it 'does a basic search in index' do
    response = @client.search(@index_uid, 'prince')
    expect(response).to be_a(Hash)
    expect(response).to have_key('hits')
    expect(response['hits']).not_to be_empty
  end

  it 'does a custom search in index' do
    response = @client.search(@index_uid, 'the', limit: 1)
    expect(response).to be_a(Hash)
    expect(response).to have_key('hits')
    expect(response['hits'].count).to eq(1)
  end
end
