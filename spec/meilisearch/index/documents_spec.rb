# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Documents' do
  let(:random_uid) { SecureRandom.hex(4) }
  let(:index) { test_client.create_index(random_uid) }

  context 'All basic tests with primary-key inference' do
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

    describe 'adding documents' do
      it 'adds documents (as a array of documents)' do
        response = index.add_documents(documents)
        expect(response).to be_a(Hash)
        expect(response).to have_key('updateId')
        index.wait_for_pending_update(response['updateId'])
        expect(index.documents.count).to eq(documents.count)
      end

      it 'adds documents in a batch (as a array of documents)' do
        response = index.add_documents_in_batches(documents, 5)
        expect(response).to be_a(Array)
        expect(response.count).to eq(2) # 2 batches, since we start with 5 < documents.count <= 10 documents
        expect(response[0]).to have_key('updateId')
        response.each do |response_object|
          index.wait_for_pending_update(response_object['updateId'])
        end
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

      it 'adds document batches synchronously (as an array of documents)' do
        response = index.add_documents_in_batches!(documents, 5)
        expect(response).to be_a(Array)
        expect(response.count).to eq(2) # 2 batches, since we start with 5 < documents.count <= 10 documents
        response.each do |response_object|
          expect(response_object).to have_key('updateId')
          expect(response_object).to have_key('status')
          expect(response_object['status']).not_to eql('enqueued')
          expect(response_object['status']).to eql('processed')
        end
        expect(index.documents.count).to eq(documents.count)
      end

      it 'infers order of fields' do
        index.add_documents!(documents)
        response = index.document(1)
        expect(response.keys).to eq(['objectId', 'title', 'comment'])
      end

      it 'infers primary-key attribute' do
        index.add_documents!(documents)
        expect(index.fetch_primary_key).to eq('objectId')
      end

      it 'create the index during document addition' do
        new_index = test_client.index('newIndex')
        response = new_index.add_documents(documents)
        expect(response).to be_a(Hash)
        expect(response).to have_key('updateId')
        new_index.wait_for_pending_update(response['updateId'])
        expect(test_client.index('newIndex').fetch_primary_key).to eq('objectId')
        expect(test_client.index('newIndex').documents.count).to eq(documents.count)
      end

      it 'adds only one document to index (as an hash of one document)' do
        new_doc = { objectId: 30, title: 'Hamlet' }
        expect do
          response = index.add_documents(new_doc)
          index.wait_for_pending_update(response['updateId'])

          expect(response).to be_a(Hash)
          expect(response).to have_key('updateId')
          expect(index.document(30)['title']).to eq('Hamlet')
        end.to(change { index.documents.length }.by(1))
      end

      it 'adds only one document synchronously to index (as an hash of one document)' do
        new_doc = { objectId: 30, title: 'Hamlet' }
        expect do
          response = index.add_documents!(new_doc)
          expect(response).to be_a(Hash)
          expect(response).to have_key('updateId')
          expect(response).to have_key('status')
          expect(response['status']).to eq('processed')
          expect(index.document(30)['title']).to eq('Hamlet')
        end.to(change { index.documents.length }.by(1))
      end

      it 'fails to add document with bad primary-key format' do
        index.add_documents!(documents)
        response = index.add_documents(objectId: 'toto et titi', title: 'Unknown')
        index.wait_for_pending_update(response['updateId'])
        expect(index.get_update_status(response['updateId'])['status']).to eq('failed')
      end

      it 'fails to add document with no primary-key' do
        index.add_documents!(documents)
        response = index.add_documents(id: 0, title: 'Unknown')
        index.wait_for_pending_update(response['updateId'])
        expect(index.get_update_status(response['updateId'])['status']).to eq('failed')
      end
    end

    describe 'accessing documents' do
      before { index.add_documents!(documents) }

      it 'gets one document from its primary-key' do
        response = index.document(123)
        expect(response).to be_a(Hash)
        expect(response['title']).to eq('Pride and Prejudice')
        expect(response['comment']).to eq('A great book')
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
        expect(response.first['objectId']).to eq(index.documents[2]['objectId'])
      end
    end

    describe 'updating documents' do
      before { index.add_documents!(documents) }

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

      it 'updates documents synchronously in index in batches (as an array of documents)' do
        id1 = 123
        id2 = 456
        updated_documents = [
          { objectId: id1,  title: 'Sense and Sensibility' },
          { objectId: id2,  title: 'The Little Prince' }
        ]
        response = index.update_documents_in_batches!(updated_documents, 1)
        expect(response).to be_a(Array)
        expect(response.count).to eq(2) # 2 batches, since we have two items with batch size 1
        response.each do |response_object|
          expect(response_object).to have_key('updateId')
          expect(response_object).to have_key('status')
          expect(response_object['status']).not_to eql('enqueued')
          expect(response_object['status']).to eql('processed')
        end
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
    end

    describe 'deleting documents' do
      before { index.add_documents!(documents) }

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
        expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
        expect do
          response = index.delete_document(id)
          index.wait_for_pending_update(response['updateId'])
          expect(response).to be_a(Hash)
          expect(response).to have_key('updateId')
        end.not_to(change { index.documents.size })
      end

      it 'deletes one document from index (with delete-batch route)' do
        id = 2
        expect do
          response = index.delete_documents(id)
          index.wait_for_pending_update(response['updateId'])
          expect(response).to be_a(Hash)
          expect(response).to have_key('updateId')
        end.to(change { index.documents.size }.by(-1))
        expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
      end

      it 'deletes one document synchronously from index (with delete-batch route)' do
        id = 2
        expect do
          response = index.delete_documents!(id)
          expect(response).to be_a(Hash)
          expect(response).to have_key('updateId')
          expect(response).to have_key('status')
          expect(response['status']).not_to eql('enqueued')
          expect(response['status']).to eql('processed')
        end.to(change { index.documents.size }.by(-1))
        expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
      end

      it 'deletes one document from index (with delete-batch route as an array of one uid)' do
        id = 123
        expect do
          response = index.delete_documents([id])
          index.wait_for_pending_update(response['updateId'])
          expect(response).to be_a(Hash)
          expect(response).to have_key('updateId')
        end.to(change { index.documents.size }.by(-1))
        expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
      end

      it 'deletes one document synchronously from index (with delete-batch route as an array of one uid)' do
        id = 123
        expect do
          response = index.delete_documents!([id])
          expect(response).to be_a(Hash)
          expect(response).to have_key('updateId')
          expect(response).to have_key('status')
          expect(response['status']).not_to eql('enqueued')
          expect(response['status']).to eql('processed')
        end.to(change { index.documents.size }.by(-1))
        expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
      end

      it 'deletes multiples documents from index' do
        docs_to_delete = [1, 4]
        expect do
          response = index.delete_documents(docs_to_delete)
          index.wait_for_pending_update(response['updateId'])
          expect(response).to be_a(Hash)
          expect(response).to have_key('updateId')
        end.to(change { index.documents.size }.by(-2))
      end

      it 'deletes multiples documents synchronously from index' do
        docs_to_delete = [1, 4]
        expect do
          response = index.delete_documents!(docs_to_delete)
          expect(response).to be_a(Hash)
          expect(response).to have_key('updateId')
          expect(response).to have_key('status')
          expect(response['status']).not_to eql('enqueued')
          expect(response['status']).to eql('processed')
        end.to(change { index.documents.size }.by(-2))
      end

      it 'clears all documents from index' do
        expect do
          response = index.delete_all_documents
          index.wait_for_pending_update(response['updateId'])
          expect(response).to be_a(Hash)
          expect(response).to have_key('updateId')
          expect(index.documents).to be_empty
        end.to(change { index.documents.size }.from(documents.size).to(0))
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
      response = index.add_documents!(documents, 'unique')
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
    let(:documents) do
      { title: 'Le Rouge et le Noir' }
    end

    it 'Impossible to push docs if the pk is missing' do
      response = index.add_documents!(documents)
      update = index.get_update_status(response['updateId'])
      expect(update['status']).to eq('failed')
      expect(update['errorCode']).to eq('missing_primary_key')
    end
  end

  context 'Impossible to update primary-key if already given during index creation' do
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
end
