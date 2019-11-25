# frozen_string_literal: true

RSpec.describe MeiliSearch::Client::Documents do
  before(:all) do
    schema = {
      objectId: [:displayed, :indexed, :identifier],
      title: [:displayed, :indexed]
    }
    @client = MeiliSearch::Client.new('http://localhost:8080', 'apiKey')
    response = @client.create_index('index_name', schema)
    @index_uid = response['uid']
  end

  after(:all) do
    @client.delete_index(@index_uid)
  end

  let(:documents) do
    [
      { objectId: 123,  title: 'Pride and Prejudice' },
      { objectId: 456,  title: 'Le Petit Prince' },
      { objectId: 1,    title: 'Alice In Wonderland' },
      { objectId: 1344, title: 'The Hobbit' },
      { objectId: 4,    title: 'Harry Potter and the Half-Blood Prince' },
      { objectId: 42,   title: 'The Hitchhiker\'s Guide to the Galaxy' }
    ]
  end

  it 'adds documents to index' do
    response = @client.add_documents(@index_uid, documents)
    sleep(0.1)
    expect(response).to be_a(Array)
    expect(response.first).to have_key('updateId')
  end

  it 'gets one document from its identifier' do
    object_id = 123
    response = @client.document(@index_uid, object_id)
    expect(response).to be_a(Hash)
    expected_title = documents.detect { |h| h[:objectId] == object_id }[:title]
    expect(response['title']).to eq(expected_title)
  end

  it 'gets all documents from index' do
    response = @client.get_all_documents(@index_uid)
    expect(response).to be_a(Array)
    expect(response.size).to eq(documents.count)
  end

  it 'deletes one document from index' do
    response = @client.delete_one_document(@index_uid, 123)
    sleep(0.1)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    browse_res = @client.get_all_documents(@index_uid)
    expect(browse_res.size).to eq(documents.count - 1)
  end

  it 'deletes multiples documents from index' do
    docs_to_delete = [1, 4]
    response = @client.delete_multiple_documents(@index_uid, docs_to_delete)
    sleep(0.1)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    browse_res = @client.get_all_documents(@index_uid)
    expect(browse_res.size).to eq(documents.count - 1 - docs_to_delete.count)
  end

  it 'clears all documents from index' do
    response = @client.clear_all_documents(@index_uid)
    sleep(0.1)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    browse_res = @client.get_all_documents(@index_uid)
    expect(browse_res).to be_empty
  end
end
