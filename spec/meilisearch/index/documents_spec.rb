# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Documents' do
  before(:all) do
    @client = MeiliSearch::Client.new($URL, $MASTER_KEY)
    clear_all_indexes(@client)
  end

  context 'All basic tests with primary-key inference' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }
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
      response = index.add_documents(documents)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.2)
      expect(index.documents.count).to eq(documents.count)
    end

    it 'infers order of fields' do
      response = index.document(1)
      expect(response.keys).to eq(['objectId', 'title', 'comment'])
    end

    it 'infers primary-key attribute' do
      expect(index.show['primaryKey']).to eq('objectId')
    end

    it 'gets one document from its primary-key' do
      object_id = 123
      response = index.document(object_id)
      expect(response).to be_a(Hash)
      expected_title = documents.detect { |h| h[:objectId] == object_id }[:title]
      expected_comment = documents.detect { |h| h[:objectId] == object_id }[:comment]
      expect(response['title']).to eq(expected_title)
      expect(response['comment']).to eq(expected_comment)
    end

    it 'browses documents' do
      response = index.documents
      expect(response).to be_a(Array)
      expect(response.size).to eq(documents.count)
      expected_titles = documents.map { |doc| doc[:title] }
      expect(response.map { |doc| doc['title'] }).to contain_exactly(*expected_titles)
    end

    it 'browses documents with query parameters' do
      response = index.documents(offset: 2, limit: 5)
      expect(response).to be_a(Array)
      expect(response.size).to eq(5)
      expect(response.first['objectId']).to eq(1)
    end

    it 'updates documents in index (as an array of documents)' do
      id1 = 123
      id2 = 456
      updated_documents = [
        { objectId: id1,  title: 'Sense and Sensibility' },
        { objectId: id2,  title: 'The Little Prince' }
      ]
      response = index.update_documents(updated_documents)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      doc1 = index.document(id1)
      doc2 = index.document(id2)
      expect(index.documents.count).to eq(documents.count)
      expect(doc1['title']).to eq(updated_documents.detect { |doc| doc[:objectId] == id1 }[:title])
      expect(doc1['comment']).to eq(documents.detect { |doc| doc[:objectId] == id1 }[:comment])
      expect(doc2['title']).to eq(updated_documents.detect { |doc| doc[:objectId] == id2 }[:title])
      expect(doc2['comment']).to eq(documents.detect { |doc| doc[:objectId] == id2 }[:comment])
    end

    it 'updates one document in index (as an hash of one document)' do
      id = 123
      updated_document = { objectId: id, title: 'Emma' }
      response = index.update_documents(updated_document)
      sleep(0.1)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(index.documents.count).to eq(documents.count)
      new_doc = index.document(id)
      expect(new_doc['title']).to eq(updated_document[:title])
      expect(new_doc['comment']).to eq(documents.detect { |doc| doc[:objectId] == id }[:comment])
    end

    it 'adds only one document to index (as an hash of one document)' do
      id = 30
      title = 'Hamlet'
      new_doc = { objectId: id, title: title }
      response = index.add_documents(new_doc)
      sleep(0.1)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(index.documents.count).to eq(documents.count + 1)
      expect(index.document(id)['title']).to eq(title)
      index.delete_document(id)
      sleep(0.1)
    end

    it 'update a document with new fields' do
      id = 2
      doc = { objectId: id, note: '8/10' }
      response = index.update_documents(doc)
      sleep(0.1)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(index.documents.count).to eq(documents.count)
      new_document = index.document(id)
      expect(new_document['title']).to eq(documents.detect { |d| d[:objectId] == id }[:title])
      expect(new_document).to have_key('note')
    end

    it 'replaces document' do
      id = 123
      new_title = 'Pride & Prejudice'
      response = index.replace_documents(objectId: id, title: 'Pride & Prejudice', note: '8.5/10')
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(index.documents.count).to eq(documents.count)
      doc = index.document(id)
      expect(doc['title']).to eq(new_title)
      expect(doc).not_to have_key('comment')
      expect(doc).to have_key('note')
    end

    it 'deletes one document from index' do
      id = 456
      response = index.delete_document(id)
      sleep(0.1)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(index.documents.size).to eq(documents.count - 1)
      expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
    end

    it 'does nothing when trying to delete a document which does not exist' do
      id = 111
      response = index.delete_document(id)
      sleep(0.1)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(index.documents.size).to eq(documents.count - 1)
      expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
    end

    it 'deletes one document from index (with delete-batch route)' do
      id = 2
      response = index.delete_documents(id)
      sleep(0.1)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(index.documents.size).to eq(documents.count - 2)
      expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
    end

    it 'deletes one document from index (with delete-batch route as an array of one uid)' do
      id = 123
      response = index.delete_documents([id])
      sleep(0.1)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(index.documents.size).to eq(documents.count - 3)
      expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
    end

    it 'deletes multiples documents from index' do
      docs_to_delete = [1, 4]
      response = index.delete_documents(docs_to_delete)
      sleep(0.1)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(index.documents.size).to eq(documents.count - 3 - docs_to_delete.count)
    end

    it 'clears all documents from index' do
      response = index.delete_all_documents
      sleep(0.1)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(index.documents).to be_empty
      expect(index.documents.size).to eq(0)
    end

    it 'fails to add document with bad primary-key format' do
      res = index.add_documents(objectId: 'toto et titi', title: 'Unknown')
      sleep(0.1)
      expect(index.get_update_status(res['updateId'])['status']).to eq('failed')
    end

    it 'fails to add document with no primary-key' do
      res = index.add_documents(id: 0, title: 'Unknown')
      sleep(0.1)
      expect(index.get_update_status(res['updateId'])['status']).to eq('failed')
    end

    it 'works with method aliases' do
      expect(index.method(:document) == index.method(:get_document)).to be_truthy
      expect(index.method(:document) == index.method(:get_one_document)).to be_truthy
      expect(index.method(:documents) == index.method(:get_documents)).to be_truthy
      expect(index.method(:add_documents) == index.method(:add_or_replace_documents)).to be_truthy
      expect(index.method(:add_documents) == index.method(:replace_documents)).to be_truthy
      expect(index.method(:update_documents) == index.method(:add_or_update_documents)).to be_truthy
      expect(index.method(:delete_documents) == index.method(:delete_multiple_documents)).to be_truthy
      expect(index.method(:delete_document) == index.method(:delete_one_document)).to be_truthy
    end
  end

  context 'Right primary-key added when pushing documents' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }
    let(:documents) do
      [
        { unique: 1, id: 1, title: 'Pride and Prejudice', comment: 'A great book' },
        { unique: 2, id: 1, title: 'Le Petit Prince',     comment: 'A french book' },
        { unique: 3, id: 1, title: 'Le Rouge et le Noir' }
      ]
    end

    it 'adds documents and the primary-key' do
      response = index.add_documents(documents, 'unique')
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.2)
      expect(index.show['primaryKey']).to eq('unique')
    end

    it 'does not take into account the new primary key' do
      response = index.update_documents({
                                          unique: 3,
                                          id: 1,
                                          title: 'The Red and the Black'
                                        }, 'id')
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.2)
      expect(index.show['primaryKey']).to eq('unique')
      doc = index.document(3)
      expect(doc['unique']).to eq(3)
      expect(doc['id']).to eq(1)
      expect(doc['title']).to eq('The Red and the Black')
    end
  end

  context 'Wrong primary-key (attribute does not exist) added when pushing documents' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }
    let(:documents) do
      { unique: 3, id: 1, title: 'Le Rouge et le Noir' }
    end

    it 'adds the primary-key but not the documents' do
      response = index.update_documents(documents, 'objectId')
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.2)
      expect(index.show['primaryKey']).to eq('objectId')
      expect(index.get_update_status(response['updateId'])['status']).to eq('failed')
    end

    it 'succeeds to add document with the primary-key' do
      response = index.add_documents({ objectId: 1, title: 'Le Rouge et le Noir' }, 'id')
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.2)
      expect(index.show['primaryKey']).to eq('objectId')
      expect(index.get_update_status(response['updateId'])['status']).to eq('processed')
      expect(index.documents.count).to eq(1)
    end

    it 'does not take into account the new primary key' do
      response = index.add_documents({ id: 2, title: 'Le Petit Prince' }, 'id')
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.2)
      expect(index.show['primaryKey']).to eq('objectId')
      expect(index.get_update_status(response['updateId'])['status']).to eq('failed')
    end
  end

  context 'Wrong primary-key (attribute bad formatted) added when pushing documents' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }
    let(:documents) do
      { id: 1, title: 'Le Rouge et le Noir' }
    end

    it 'adds the primary-key but not the documents' do
      response = index.add_documents(documents, 'title')
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.2)
      expect(index.show['primaryKey']).to eq('title')
      expect(index.get_update_status(response['updateId'])['status']).to eq('failed')
      expect(index.documents.count).to eq(0)
    end
  end

  context 'Impossible to infer the primary-key' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }
    let(:documents) do
      { title: 'Le Rouge et le Noir' }
    end

    it 'returns a 400' do
      expect do
        index.add_documents(documents)
      end.to raise_missing_primary_key_meilisearch_api_error
    end
  end

  context 'Impossible to udpate primary-key if already given during index creation' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }
    let(:documents) do
      { id: 1, unique: 1, title: 'Le Rouge et le Noir' }
    end

    it 'adds the documents anyway' do
      response = index.add_documents(documents, 'unique')
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.2)
      expect(index.show['primaryKey']).to eq('unique')
      expect(index.documents.count).to eq(1)
    end
  end
end
