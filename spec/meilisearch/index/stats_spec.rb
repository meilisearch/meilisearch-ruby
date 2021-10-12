# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Stats' do
  before(:all) do
    @documents = [
      { objectId: 123,  title: 'Pride and Prejudice' },
      { objectId: 456,  title: 'Le Petit Prince' },
      { objectId: 1,    title: 'Alice In Wonderland' },
      { objectId: 1344, title: 'The Hobbit' },
      { objectId: 4,    title: 'Harry Potter and the Half-Blood Prince' },
      { objectId: 42,   title: 'The Hitchhiker\'s Guide to the Galaxy' }
    ]
    client = MeiliSearch::Client.new(URL, MASTER_KEY)
    clear_all_indexes(client)
    @index = client.create_index('indexUID')
    response = @index.add_documents(@documents)
    @index.wait_for_pending_update(response['updateId'])
  end

  after(:all) do
    @index.delete
  end

  it 'returns stats of the index' do
    response = @index.stats
    expect(response).to be_a(Hash)
    expect(response).not_to be_empty
  end

  it 'gets the number of documents' do
    response = @index.number_of_documents
    expect(response).to eq(@documents.count)
  end

  it 'gets the distribution of fields' do
    response = @index.field_distribution
    expect(response).to be_a(Hash)
  end

  it 'knows when it is indexing' do
    expect(@index.indexing?).to be_falsy
  end
end
