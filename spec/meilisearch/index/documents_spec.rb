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
      index.wait_for_pending_update(response['updateId'])
      expect(index.documents.count).to eq(documents.count)
    end

    it 'adds documents synchronously (as an array of documents)' do
      response = index.add_documents!(documents)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(response).to have_key('status')
      expect(response['status']).not_to eql('enqueued')
      expect(response['status']).to eql('processed')
      expect(index.documents.count).to eq(documents.count)
    end

    it 'infers order of fields' do
      response = index.document(1)
      expect(response.keys).to eq(['objectId', 'title', 'comment'])
    end

    it 'infers primary-key attribute' do
      expect(index.fetch_primary_key).to eq('objectId')
    end

    it 'create the index during document addition' do
      new_index = @client.index('newIndex')
      response = new_index.add_documents(documents)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      new_index.wait_for_pending_update(response['updateId'])
      expect(@client.index('newIndex').fetch_primary_key).to eq('objectId')
      expect(@client.index('newIndex').documents.count).to eq(documents.count)
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
      index.wait_for_pending_update(response['updateId'])
      doc1 = index.document(id1)
      doc2 = index.document(id2)
      expect(index.documents.count).to eq(documents.count)
      expect(doc1['title']).to eq(updated_documents.detect { |doc| doc[:objectId] == id1 }[:title])
      expect(doc1['comment']).to eq(documents.detect { |doc| doc[:objectId] == id1 }[:comment])
      expect(doc2['title']).to eq(updated_documents.detect { |doc| doc[:objectId] == id2 }[:title])
      expect(doc2['comment']).to eq(documents.detect { |doc| doc[:objectId] == id2 }[:comment])
    end

    it 'updates documents synchronously in index (as an array of documents)' do
      id1 = 123
      id2 = 456
      updated_documents = [
        { objectId: id1,  title: 'Sense and Sensibility' },
        { objectId: id2,  title: 'The Little Prince' }
      ]
      response = index.update_documents!(updated_documents)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(response).to have_key('status')
      expect(response['status']).not_to eql('enqueued')
      expect(response['status']).to eql('processed')
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
      index.wait_for_pending_update(response['updateId'])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(index.documents.count).to eq(documents.count)
      new_doc = index.document(id)
      expect(new_doc['title']).to eq(updated_document[:title])
      expect(new_doc['comment']).to eq(documents.detect { |doc| doc[:objectId] == id }[:comment])
    end

    it 'updates one document synchronously in index (as an hash of one document)' do
      id = 123
      updated_document = { objectId: id, title: 'Emma' }
      response = index.update_documents!(updated_document)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(response).to have_key('status')
      expect(response['status']).not_to eql('enqueued')
      expect(response['status']).to eql('processed')
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
      index.wait_for_pending_update(response['updateId'])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(index.documents.count).to eq(documents.count + 1)
      expect(index.document(id)['title']).to eq(title)
      response = index.delete_document(id)
      index.wait_for_pending_update(response['updateId'])
    end

    it 'adds only one document synchronously to index (as an hash of one document)' do
      id = 30
      title = 'Hamlet'
      new_doc = { objectId: id, title: title }
      response = index.add_documents!(new_doc)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(response).to have_key('status')
      expect(response['status']).not_to eql('enqueued')
      expect(response['status']).to eql('processed')
      expect(index.documents.count).to eq(documents.count + 1)
      expect(index.document(id)['title']).to eq(title)
      response = index.delete_document(id)
      index.wait_for_pending_update(response['updateId'])
    end

    it 'update a document with new fields' do
      id = 2
      doc = { objectId: id, note: '8/10' }
      response = index.update_documents(doc)
      index.wait_for_pending_update(response['updateId'])
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
      index.wait_for_pending_update(response['updateId'])
      expect(index.documents.count).to eq(documents.count)
      doc = index.document(id)
      expect(doc['title']).to eq(new_title)
      expect(doc).not_to have_key('comment')
      expect(doc).to have_key('note')
    end

    it 'deletes one document from index' do
      id = 456
      response = index.delete_document(id)
      index.wait_for_pending_update(response['updateId'])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(index.documents.size).to eq(documents.count - 1)
      expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
    end

    it 'deletes one document synchronously from index' do
      id = 456
      response = index.delete_document!(id)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(response).to have_key('status')
      expect(response['status']).not_to eql('enqueued')
      expect(response['status']).to eql('processed')
      expect(index.documents.size).to eq(documents.count - 1)
      expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
    end

    it 'does nothing when trying to delete a document which does not exist' do
      id = 111
      response = index.delete_document(id)
      index.wait_for_pending_update(response['updateId'])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(index.documents.size).to eq(documents.count - 1)
      expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
    end

    it 'deletes one document from index (with delete-batch route)' do
      id = 2
      response = index.delete_documents(id)
      index.wait_for_pending_update(response['updateId'])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(index.documents.size).to eq(documents.count - 2)
      expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
    end

    it 'deletes one document synchronously from index (with delete-batch route)' do
      id = 2
      response = index.delete_documents!(id)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(response).to have_key('status')
      expect(response['status']).not_to eql('enqueued')
      expect(response['status']).to eql('processed')
      expect(index.documents.size).to eq(documents.count - 2)
      expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
    end

    it 'deletes one document from index (with delete-batch route as an array of one uid)' do
      id = 123
      response = index.delete_documents([id])
      index.wait_for_pending_update(response['updateId'])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(index.documents.size).to eq(documents.count - 3)
      expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
    end

    it 'deletes one document synchronously from index (with delete-batch route as an array of one uid)' do
      id = 123
      response = index.delete_documents!([id])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(response).to have_key('status')
      expect(response['status']).not_to eql('enqueued')
      expect(response['status']).to eql('processed')
      expect(index.documents.size).to eq(documents.count - 3)
      expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
    end

    it 'deletes multiples documents from index' do
      docs_to_delete = [1, 4]
      response = index.delete_documents(docs_to_delete)
      index.wait_for_pending_update(response['updateId'])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(index.documents.size).to eq(documents.count - 3 - docs_to_delete.count)
    end

    it 'deletes multiples documents synchronously from index' do
      docs_to_delete = [1, 4]
      response = index.delete_documents!(docs_to_delete)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(response).to have_key('status')
      expect(response['status']).not_to eql('enqueued')
      expect(response['status']).to eql('processed')
      expect(index.documents.size).to eq(documents.count - 3 - docs_to_delete.count)
    end

    it 'clears all documents from index' do
      response = index.delete_all_documents
      index.wait_for_pending_update(response['updateId'])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(index.documents).to be_empty
      expect(index.documents.size).to eq(0)
    end

    it 'clears all documents synchronously from index' do
      response = index.delete_all_documents!
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      expect(response).to have_key('status')
      expect(response['status']).not_to eql('enqueued')
      expect(response['status']).to eql('processed')
      expect(index.documents).to be_empty
      expect(index.documents.size).to eq(0)
    end

    it 'fails to add document with bad primary-key format' do
      response = index.add_documents(objectId: 'toto et titi', title: 'Unknown')
      index.wait_for_pending_update(response['updateId'])
      expect(index.get_update_status(response['updateId'])['status']).to eq('failed')
    end

    it 'fails to add document with no primary-key' do
      response = index.add_documents(id: 0, title: 'Unknown')
      index.wait_for_pending_update(response['updateId'])
      expect(index.get_update_status(response['updateId'])['status']).to eq('failed')
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
      index.wait_for_pending_update(response['updateId'])
      expect(index.fetch_primary_key).to eq('unique')
    end

    it 'does not take into account the new primary key' do
      response = index.update_documents({
                                          unique: 3,
                                          id: 1,
                                          title: 'The Red and the Black'
                                        }, 'id')
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.fetch_primary_key).to eq('unique')
      doc = index.document(3)
      expect(doc['unique']).to eq(3)
      expect(doc['id']).to eq(1)
      expect(doc['title']).to eq('The Red and the Black')
    end
  end

  context 'Wrong primary-key (attribute does not exist) when pushing documents' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }
    let(:documents) do
      { unique: 3, id: 1, title: 'Le Rouge et le Noir' }
    end

    it 'does not add the primary key and the documents either' do
      response = index.update_documents(documents, 'objectId')
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.fetch_primary_key).to be_nil
      expect(index.get_update_status(response['updateId'])['status']).to eq('failed')
    end
  end

  context 'Wrong primary-key (attribute bad formatted) when pushing documents' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }
    let(:documents) do
      { id: 1, title: 'Le Rouge et le Noir' }
    end

    it 'does not add the primary key and the documents either' do
      response = index.add_documents(documents, 'title')
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.fetch_primary_key).to be_nil
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

  context 'Impossible to update primary-key if already given during index creation' do
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
      index.wait_for_pending_update(response['updateId'])
      expect(index.fetch_primary_key).to eq('unique')
      expect(index.documents.count).to eq(1)
    end
  end

  context 'Add document with client options' do
    let(:documents) do
      { id: 1, unique: 1, title: 'Le Rouge et le Noir' }
    end

    it 'uses the timeout client option' do
      zero_timeout_client = MeiliSearch::Client.new($URL, $MASTER_KEY, @options = { timeout: 0 })
      new_index = zero_timeout_client.index('newIndex')
      expect do
        new_index.add_documents(documents)
      end.to raise_error(Timeout::Error)
    end

    it 'uses the max_retries client option' do
      max_retries_client = MeiliSearch::Client.new($URL, $MASTER_KEY, @options = { max_retries: 2 })
      http = Net::HTTP.new('localhost', 7700)
      new_index = max_retries_client.index('newIndex')
      expect(Net::HTTP).to receive(:new).with('localhost', 7700).and_return(http)
      expect(http).to receive(:max_retries=).with(2)
      new_index.add_documents(documents)
    end
  end
end
