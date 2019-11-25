# frozen_string_literal: true

RSpec.describe MeiliSearch::Index::Documents do
  before(:all) do
    client = MeiliSearch::Client.new($URL, $API_KEY)
    @index = client.create_index(name: 'Books')
  end

  after(:all) do
    @index.delete
  end

  let(:documents) do
    [
      { objectId: 123,  title: 'Pride and Prejudice',                    comment: 'A great book' },
      { objectId: 456,  title: 'Le Petit Prince',                        comment: 'A french book' },
      { objectId: 1,    title: 'Alice In Wonderland',                    comment: 'A weird book' },
      { objectId: 1344, title: 'The Hobbit',                             comment: 'An awesome book' },
      { objectId: 4,    title: 'Harry Potter and the Half-Blood Prince', comment: 'The best book' },
      { objectId: 42,   title: 'The Hitchhiker\'s Guide to the Galaxy' },
      { objectId: 2,    title: 'Le Rouge et le Noir' }
    ]
  end

  it 'adds documents (as a array of documents)' do
    response = @index.add_documents(documents)
    sleep(0.2)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    expect(@index.documents.count).to eq(documents.count)
  end

  it 'infers the schema' do
    response = @index.schema
    expect(response).to have_key('objectId')
    expect(response).to have_key('title')
    expect(response).to have_key('comment')
  end

  it 'gets one document from its identifier' do
    object_id = 123
    response = @index.document(object_id)
    expect(response).to be_a(Hash)
    expected_title = documents.detect { |h| h[:objectId] == object_id }[:title]
    expected_comment = documents.detect { |h| h[:objectId] == object_id }[:comment]
    expect(response['title']).to eq(expected_title)
    expect(response['comment']).to eq(expected_comment)
  end

  it 'browses documents' do
    response = @index.documents
    expect(response).to be_a(Array)
    expect(response.size).to eq(documents.count)
    expected_titles = documents.map { |doc| doc[:title] }
    expect(response.map { |doc| doc['title'] }).to contain_exactly(*expected_titles)
  end

  it 'browses documents with query parameters' do
    response = @index.documents(offset: 2, limit: 5)
    expect(response).to be_a(Array)
    expect(response.size).to eq(5)
    expect(response.first['objectId']).to eq(123)
  end

  it 'updates documents in index (as an array of documents)' do
    id1 = 123
    id2 = 456
    updated_documents = [
      { objectId: id1,  title: 'Sense and Sensibility' },
      { objectId: id2,  title: 'The Little Prince' }
    ]
    response = @index.update_documents(updated_documents)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    sleep(0.1)
    doc1 = @index.document(id1)
    doc2 = @index.document(id2)
    expect(@index.documents.count).to eq(documents.count)
    expect(doc1['title']).to eq(updated_documents.detect { |doc| doc[:objectId] == id1 }[:title])
    expect(doc1['comment']).to eq(documents.detect { |doc| doc[:objectId] == id1 }[:comment])
    expect(doc2['title']).to eq(updated_documents.detect { |doc| doc[:objectId] == id2 }[:title])
    expect(doc2['comment']).to eq(documents.detect { |doc| doc[:objectId] == id2 }[:comment])
  end

  it 'updates one document in index (as an hash of one document)' do
    id = 123
    updated_document = { objectId: id, title: 'Emma' }
    response = @index.update_documents(updated_document)
    sleep(0.1)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    expect(@index.documents.count).to eq(documents.count)
    new_doc = @index.document(id)
    expect(new_doc['title']).to eq(updated_document[:title])
    expect(new_doc['comment']).to eq(documents.detect { |doc| doc[:objectId] == id }[:comment])
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

  it 'adds a document with fields unknown by the schema (these fields are ignored)' do
    id = 30
    title = 'Ulysses'
    new_doc = { objectId: id, title: title, note: '8/10' }
    response = @index.add_documents(new_doc)
    sleep(0.1)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    expect(@index.documents.count).to eq(documents.count + 1)
    new_document = @index.document(id)
    expect(new_document['title']).to eq(title)
    expect(new_document).not_to have_key('note')
    @index.delete_document(id)
    sleep(0.1)
  end

  it 'replaces document' do
    id = 123
    new_title = 'Pride & Prejudice'
    response = @index.replace_documents(objectId: id, title: 'Pride & Prejudice')
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    sleep(0.1)
    expect(@index.documents.count).to eq(documents.count)
    doc = @index.document(id)
    expect(doc['title']).to eq(new_title)
    expect(doc).not_to have_key('comment')
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

  it 'works with method aliases' do
    expect(@index.method(:document) == @index.method(:get_document)).to be_truthy
    expect(@index.method(:document) == @index.method(:get_one_document)).to be_truthy
    expect(@index.method(:documents) == @index.method(:get_documents)).to be_truthy
    expect(@index.method(:add_documents) == @index.method(:add_or_replace_documents)).to be_truthy
    expect(@index.method(:add_documents) == @index.method(:replace_documents)).to be_truthy
    expect(@index.method(:update_documents) == @index.method(:add_or_update_documents)).to be_truthy
    expect(@index.method(:clear_documents) == @index.method(:clear_all_documents)).to be_truthy
    expect(@index.method(:delete_documents) == @index.method(:delete_multiple_documents)).to be_truthy
    expect(@index.method(:delete_document) == @index.method(:delete_one_document)).to be_truthy
  end
end
