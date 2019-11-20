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
    @index_name = 'index_name'
    @client = MeiliSearch::Client.new('http://localhost:8080', 'apiKey')
    @client.create_index(@index_name, schema)
    @client.add_documents(@index_name, documents)
    sleep(0.1)
  end

  after(:all) do
    @client.delete_index(@index_name)
  end

  let(:client)     { @client }
  let(:index_name) { @index_name }

  it 'does a basic search in index' do
    response = @client.search(index_name, 'prince')
    expect(response).to be_a(Hash)
    expect(response).to have_key('hits')
    expect(response['hits']).not_to be_empty
  end

  it 'does a custom search in index' do
    response = @client.search(index_name, 'the', { limit: 1 })
    expect(response).to be_a(Hash)
    expect(response).to have_key('hits')
    expect(response['hits'].count).to eq(1)
  end

end
