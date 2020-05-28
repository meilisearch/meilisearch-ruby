# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Search' do
  before(:all) do
    documents = [
      { objectId: 123,  title: 'Pride and Prejudice' },
      { objectId: 456,  title: 'Le Petit Prince' },
      { objectId: 1,    title: 'Alice In Wonderland' },
      { objectId: 1344, title: 'The Hobbit' },
      { objectId: 4,    title: 'Harry Potter and the Half-Blood Prince' },
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

  it 'does a basic search in index' do
    response = @index.search('prince')
    expect(response).to be_a(Hash)
    expect(response).to have_key('hits')
    expect(response['hits']).not_to be_empty
    expect(response['hits'].first).not_to have_key('_formatted')
  end

  it 'does a custom search with limit' do
    response = @index.search('the', limit: 1)
    expect(response).to be_a(Hash)
    expect(response).to have_key('hits')
    expect(response['hits'].count).to eq(1)
    expect(response['hits'].first).not_to have_key('_formatted')
  end

  it 'does a custom search with highlight' do
    response = @index.search('the', attributesToHighlight: '*')
    expect(response).to be_a(Hash)
    expect(response).to have_key('hits')
    expect(response['hits'].count).to eq(3)
    expect(response['hits'].first).to have_key('_formatted')
  end
end
