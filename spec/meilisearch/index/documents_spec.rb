# frozen_string_literal: true

RSpec.describe MeiliSearch::Index::Documents do
  before(:all) do
    schema = {
      objectId: [:displayed, :indexed, :identifier],
      title: [:displayed, :indexed]
    }
    client = MeiliSearch::Client.new($URL, $API_KEY)
    @index = client.create_index(name: 'Index name', schema: schema)
  end

  after(:all) do
    @index.delete
  end

  let(:documents) do
    [
      { objectId: 123,  title: 'Pride and Prejudice' },
      { objectId: 456,  title: 'Le Petit Prince' },
      { objectId: 1,    title: 'Alice In Wonderland' },
      { objectId: 1344, title: 'The Hobbit' },
      { objectId: 4,    title: 'Harry Potter and the Half-Blood Prince' },
      { objectId: 42,   title: 'The Hitchhiker\'s Guide to the Galaxy' },
      { objectId: 2,    title: 'Le Rouge et le Noir' }
    ]
  end

  it 'adds documents (as a array of documents)' do
    response = @index.add_documents(documents)
    sleep(0.1)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    expect(@index.documents.count).to eq(documents.count)
  end

  it 'gets one document from its identifier' do
    object_id = 123
    response = @index.document(object_id)
    expect(response).to be_a(Hash)
    expected_title = documents.detect { |h| h[:objectId] == object_id }[:title]
    expect(response['title']).to eq(expected_title)
  end

  it 'gets all documents' do
    response = @index.get_all_documents
    expect(response).to be_a(Array)
    expect(response.size).to eq(documents.count)
    expected_titles = documents.map { |doc| doc[:title] }
    expect(response.map { |doc| doc['title']}).to contain_exactly(*expected_titles)
  end

  it 'gets all documents with query parameters' do
    response = @index.documents({offset: 2, limit: 5})
    expect(response).to be_a(Array)
    expect(response.size).to eq(5)
    expect(response.first['objectId']).to eq(123)
  end

  it 'updates documents in index (as an array of documents)' do
    updated_documents = [
      { objectId: 123,  title: 'Sense and Sensibility' },
      { objectId: 456,  title: 'The Little Prince' }
    ]
    response = @index.update_documents(updated_documents)
    sleep(0.1)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    new_docs = @index.documents
    expect(new_docs.count).to eq(documents.count)
    expect(new_docs.detect { |doc| doc['objectId'] == 123 }['title']).to eq(updated_documents.detect {|doc| doc[:objectId] == 123 }[:title])
    expect(new_docs.detect { |doc| doc['objectId'] == 456 }['title']).to eq(updated_documents.detect {|doc| doc[:objectId] == 456 }[:title])
  end

  it 'updates one document in index (as an hash of one document)' do
    updated_document = { objectId: 123,  title: 'Emma' }
    response = @index.update_documents(updated_document)
    sleep(0.1)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    new_docs = @index.documents
    expect(new_docs.count).to eq(documents.count)
    expect(new_docs.detect { |doc| doc['objectId'] == 123 }['title']).to eq(updated_document[:title])
  end

  it 'adds only one document to index (as an hash of one document)' do
    id = 30
    title = 'Hamlet'
    new_doc = { objectId: id, title: title }
    response = @index.add_documents(new_doc)
    sleep(0.1)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    expect(@index.documents.count).to eq(documents.count + 1)
    expect(@index.document(id)['title']).to eq(title)
    @index.delete_document(id)
    sleep(0.1)
  end

  it 'deletes one document from index' do
    id = 456
    response = @index.delete_document(id)
    sleep(0.1)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    expect(@index.documents.size).to eq(documents.count - 1)
    expect { @index.document(id) }.to raise_meilisearch_http_error_with(404)
  end

  it 'does nothing when trying to delete a document which does not exist' do
    id = 111
    response = @index.delete_document(id)
    sleep(0.1)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    expect(@index.documents.size).to eq(documents.count - 1)
    expect { @index.document(id) }.to raise_meilisearch_http_error_with(404)
  end

  it 'deletes one document from index (with delete_multiple_documents routes)' do
    id = 2
    response = @index.delete_documents(id)
    sleep(0.1)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    expect(@index.documents.size).to eq(documents.count - 2)
    expect { @index.document(id) }.to raise_meilisearch_http_error_with(404)
  end

  it 'deletes one document from index (with delete_multiple_documents routes as an array of one uid)' do
    id = 123
    response = @index.delete_documents([id])
    sleep(0.1)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    expect(@index.documents.size).to eq(documents.count - 3)
    expect { @index.document(id) }.to raise_meilisearch_http_error_with(404)
  end

  it 'deletes multiples documents from index' do
    docs_to_delete = [1, 4]
    response = @index.delete_documents(docs_to_delete)
    sleep(0.1)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    expect(@index.documents.size).to eq(documents.count - 3 - docs_to_delete.count)
  end

  it 'clears all documents from index' do
    response = @index.clear_documents
    sleep(0.1)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    expect(@index.documents).to be_empty
    expect(@index.documents.size).to eq(0)
  end
end
