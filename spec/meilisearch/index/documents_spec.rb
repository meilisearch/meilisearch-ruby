# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Documents' do
  let(:index) { client.index(random_uid) }

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
        task = index.add_documents(documents)

        expect(task['type']).to eq('documentAdditionOrUpdate')
        client.wait_for_task(task['taskUid'])
        expect(index.documents['results'].count).to eq(documents.count)
      end

      it 'keeps the structure of the original documents' do
        docs = [
          { object_id: 123, my_title: 'Pride and Prejudice', 'my-comment': 'A great book' }
        ]

        task = index.add_documents(docs)
        client.wait_for_task(task['taskUid'])

        expect(index.documents['results'].first.keys).to eq(docs.first.keys.map(&:to_s))
      end

      it 'adds JSON documents (as a array of documents)' do
        documents = <<~JSON
          [
            { "objectRef": 123,  "title": "Pride and Prejudice",                    "comment": "A great book" },
            { "objectRef": 456,  "title": "Le Petit Prince",                        "comment": "A french book" },
            { "objectRef": 1,    "title": "Alice In Wonderland",                    "comment": "A weird book" },
            { "objectRef": 1344, "title": "The Hobbit",                             "comment": "An awesome book" },
            { "objectRef": 4,    "title": "Harry Potter and the Half-Blood Prince", "comment": "The best book" }
          ]
        JSON
        response = index.add_documents_json(documents, 'objectRef')

        index.wait_for_task(response['taskUid'])
        expect(index.documents['results'].count).to eq(5)
      end

      it 'adds NDJSON documents (as a array of documents)' do
        documents = <<~NDJSON
          { "objectRef": 123,  "title": "Pride and Prejudice",                    "comment": "A great book" }
          { "objectRef": 456,  "title": "Le Petit Prince",                        "comment": "A french book" }
          { "objectRef": 1,    "title": "Alice In Wonderland",                    "comment": "A weird book" }
          { "objectRef": 4,    "title": "Harry Potter and the Half-Blood Prince", "comment": "The best book" }
        NDJSON
        response = index.add_documents_ndjson(documents, 'objectRef')

        index.wait_for_task(response['taskUid'])
        expect(index.documents['results'].count).to eq(4)
      end

      it 'adds CSV documents (as a array of documents)' do
        documents = <<~CSV
          "objectRef:number","title:string","comment:string"
          "1239","Pride and Prejudice","A great book"
          "4569","Le Petit Prince","A french book"
          "49","Harry Potter and the Half-Blood Prince","The best book"
        CSV
        response = index.add_documents_csv(documents, 'objectRef')

        index.wait_for_task(response['taskUid'])
        expect(index.documents['results'].count).to eq(3)
      end

      it 'adds CSV documents (as an array of documents with a different separator)' do
        documents = <<~CSV
          "objectRef:number"|"title:string"|"comment:string"
          "1239"|"Pride and Prejudice"|"A great book"
          "4569"|"Le Petit Prince"|"A french book"
          "49"|"Harry Potter and the Half-Blood Prince"|"The best book"
        CSV

        response = index.add_documents_csv(documents, 'objectRef', '|')
        index.wait_for_task(response['taskUid'])

        expect(index.documents['results'].count).to eq(3)
        expect(index.documents['results'][1]['objectRef']).to eq(4569)
        expect(index.documents['results'][1]['title']).to eq('Le Petit Prince')
        expect(index.documents['results'][1]['comment']).to eq('A french book')
      end

      it 'adds documents in a batch (as a array of documents)' do
        task = index.add_documents_in_batches(documents, 5)
        expect(task).to be_a(Array)
        expect(task.count).to eq(2) # 2 batches, since we start with 5 < documents.count <= 10 documents
        expect(task[0]).to have_key('taskUid')
        task.each do |task_object|
          client.wait_for_task(task_object['taskUid'])
        end
        expect(index.documents['results'].count).to eq(documents.count)
      end

      it 'adds documents synchronously (as an array of documents)' do
        task = index.add_documents(documents, wait: true)

        expect(task).to have_key('status')
        expect(task['status']).not_to eql('enqueued')
        expect(task['status']).to eql('succeeded')
        expect(index.documents['results'].count).to eq(documents.count)
      end

      it 'adds document batches synchronously (as an array of documents)' do
        task = index.add_documents_in_batches(documents, 5, wait: true)
        expect(task).to be_a(Array)
        expect(task.count).to eq(2) # 2 batches, since we start with 5 < documents.count <= 10 documents
        task.each do |task_object|
          expect(task_object).to have_key('uid')
          expect(task_object).to have_key('status')
          expect(task_object['status']).not_to eql('enqueued')
          expect(task_object['status']).to eql('succeeded')
        end
        expect(index.documents['results'].count).to eq(documents.count)
      end

      it 'infers order of fields' do
        index.add_documents(documents, wait: true)
        task = index.document(1)
        expect(task.keys).to eq(['objectId', 'title', 'comment'])
      end

      it 'slices response fields' do
        index.add_documents(documents, wait: true)

        task = index.document(1, fields: ['title'])

        expect(task.keys).to eq(['title'])
      end

      it 'infers primary-key attribute' do
        index.add_documents(documents, wait: true)
        expect(index.fetch_primary_key).to eq('objectId')
      end

      it 'create the index during document addition' do
        new_index = client.index('books')
        task = new_index.add_documents(documents)

        new_index.wait_for_task(task['taskUid'])
        expect(client.index('books').fetch_primary_key).to eq('objectId')
        expect(client.index('books').documents['results'].count).to eq(documents.count)
      end

      it 'adds only one document to index (as an hash of one document)' do
        new_doc = { objectId: 30, title: 'Hamlet' }
        client.create_index('books', wait: true)
        new_index = client.index('books')
        expect do
          new_index.add_documents(new_doc, wait: true)

          expect(new_index.document(30)['title']).to eq('Hamlet')
        end.to(change { new_index.documents['results'].length }.by(1))
      end

      it 'adds only one document synchronously to index (as an hash of one document)' do
        new_doc = { objectId: 30, title: 'Hamlet' }
        client.create_index('books', wait: true)
        new_index = client.index('books')
        expect do
          task = new_index.add_documents(new_doc, wait: true)

          expect(task).to have_key('status')
          expect(task['status']).to eq('succeeded')
          expect(new_index.document(30)['title']).to eq('Hamlet')
        end.to(change { new_index.documents['results'].length }.by(1))
      end

      it 'fails to add document with bad primary-key format' do
        index.add_documents(documents, wait: true)
        task = index.add_documents({ objectId: 'toto et titi', title: 'Unknown' })
        client.wait_for_task(task['taskUid'])
        expect(index.task(task['taskUid'])['status']).to eq('failed')
      end

      it 'fails to add document with no primary-key' do
        index.add_documents(documents, wait: true)
        task = index.add_documents({ id: 0, title: 'Unknown' })
        client.wait_for_task(task['taskUid'])
        expect(index.task(task['taskUid'])['status']).to eq('failed')
      end
    end

    describe 'accessing documents' do
      before do
        index.add_documents(documents)

        task = index.update_filterable_attributes(['title', 'objectId'])
        client.wait_for_task(task['taskUid'])
      end

      it 'gets one document from its primary-key' do
        task = index.document(123)
        expect(task).to be_a(Hash)
        expect(task['title']).to eq('Pride and Prejudice')
        expect(task['comment']).to eq('A great book')
      end

      it 'browses documents' do
        docs = index.documents['results']

        expect(docs).to be_a(Array)
        expect(docs.size).to eq(documents.count)
        expected_titles = documents.map { |doc| doc[:title] }
        expect(docs.map { |doc| doc['title'] }).to contain_exactly(*expected_titles)
      end

      it 'browses documents with query parameters' do
        docs = index.documents(offset: 2, limit: 5)['results']

        expect(docs).to be_a(Array)
        expect(docs.size).to eq(5)
        expect(docs.first['objectId']).to eq(index.documents['results'][2]['objectId'])
      end

      it 'browses documents with fields' do
        docs = index.documents(fields: ['title'])['results']

        expect(docs).to be_a(Array)
        expect(docs.first.keys).to eq(['title'])
      end

      it 'retrieves documents by filters' do
        docs = index.documents(filter: 'objectId > 400')['results']

        expect(docs).to be_a(Array)
        expect(docs.first).to eq({
                                   'objectId' => 456,
                                   'title' => 'Le Petit Prince',
                                   'comment' => 'A french book'
                                 })
      end

      it 'retrieves documents by filters & other parameters' do
        docs = index.documents(fields: ['title'], filter: 'objectId > 100')['results']

        expect(docs).to be_a(Array)
        expect(docs.size).to eq(3)
        expect(docs.first.keys).to eq(['title'])
      end
    end

    describe 'updating documents' do
      before { index.add_documents(documents, wait: true) }

      it 'updates documents in index (as an array of documents)' do
        id1 = 123
        id2 = 456
        updated_documents = [
          { objectId: id1,  title: 'Sense and Sensibility' },
          { objectId: id2,  title: 'The Little Prince' }
        ]
        task = index.update_documents(updated_documents)
        client.wait_for_task(task['taskUid'])
        doc1 = index.document(id1)
        doc2 = index.document(id2)
        expect(index.documents['results'].count).to eq(documents.count)
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
        task = index.update_documents(updated_documents, wait: true)

        expect(task).to have_key('status')
        expect(task['status']).not_to eql('enqueued')
        expect(task['status']).to eql('succeeded')
        doc1 = index.document(id1)
        doc2 = index.document(id2)
        expect(index.documents['results'].count).to eq(documents.count)
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
        task = index.update_documents_in_batches(updated_documents, 1, wait: true)
        expect(task).to be_a(Array)
        expect(task.count).to eq(2) # 2 batches, since we have two items with batch size 1
        task.each do |task_object|
          expect(task_object).to have_key('uid')
          expect(task_object).to have_key('status')
          expect(task_object['status']).not_to eql('enqueued')
          expect(task_object['status']).to eql('succeeded')
        end
        doc1 = index.document(id1)
        doc2 = index.document(id2)
        expect(index.documents['results'].count).to eq(documents.count)
        expect(doc1['title']).to eq(updated_documents.detect { |doc| doc[:objectId] == id1 }[:title])
        expect(doc1['comment']).to eq(documents.detect { |doc| doc[:objectId] == id1 }[:comment])
        expect(doc2['title']).to eq(updated_documents.detect { |doc| doc[:objectId] == id2 }[:title])
        expect(doc2['comment']).to eq(documents.detect { |doc| doc[:objectId] == id2 }[:comment])
      end

      it 'updates one document in index (as an hash of one document)' do
        id = 123
        updated_document = { objectId: id, title: 'Emma' }
        task = index.update_documents(updated_document)
        client.wait_for_task(task['taskUid'])

        expect(index.documents['results'].count).to eq(documents.count)
        new_doc = index.document(id)
        expect(new_doc['title']).to eq(updated_document[:title])
        expect(new_doc['comment']).to eq(documents.detect { |doc| doc[:objectId] == id }[:comment])
      end

      it 'updates one document synchronously in index (as an hash of one document)' do
        id = 123
        updated_document = { objectId: id, title: 'Emma' }
        task = index.update_documents(updated_document, wait: true)

        expect(task).to have_key('status')
        expect(task['status']).not_to eql('enqueued')
        expect(task['status']).to eql('succeeded')
        expect(index.documents['results'].count).to eq(documents.count)
        new_doc = index.document(id)
        expect(new_doc['title']).to eq(updated_document[:title])
        expect(new_doc['comment']).to eq(documents.detect { |doc| doc[:objectId] == id }[:comment])
      end

      it 'update a document with new fields' do
        id = 2
        doc = { objectId: id, note: '8/10' }
        task = index.update_documents(doc)
        client.wait_for_task(task['taskUid'])

        expect(index.documents['results'].count).to eq(documents.count)
        new_document = index.document(id)
        expect(new_document['title']).to eq(documents.detect { |d| d[:objectId] == id }[:title])
        expect(new_document).to have_key('note')
      end

      it 'replaces document' do
        id = 123
        new_title = 'Pride & Prejudice'
        task = index.replace_documents({ objectId: id, title: 'Pride & Prejudice', note: '8.5/10' })

        client.wait_for_task(task['taskUid'])
        expect(index.documents['results'].count).to eq(documents.count)
        doc = index.document(id)
        expect(doc['title']).to eq(new_title)
        expect(doc).not_to have_key('comment')
        expect(doc).to have_key('note')
      end
    end

    describe 'deleting documents' do
      before { index.add_documents(documents, wait: true) }

      it 'deletes one document from index' do
        id = 456
        task = index.delete_document(id)
        client.wait_for_task(task['taskUid'])

        expect(index.documents['results'].size).to eq(documents.count - 1)
        expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
      end

      it 'deletes one document synchronously from index' do
        id = 456
        task = index.delete_document(id, wait: true)

        expect(task).to have_key('status')
        expect(task['status']).not_to eql('enqueued')
        expect(task['status']).to eql('succeeded')
        expect(index.documents['results'].size).to eq(documents.count - 1)
        expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
      end

      it 'does nothing when trying to delete a document which does not exist' do
        id = 111
        expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
        expect do
          task = index.delete_document(id)
          client.wait_for_task(task['taskUid'])
        end.not_to(change { index.documents['results'].size })
      end

      it 'deletes one document from index (with delete-batch route)' do
        id = 2
        expect do
          task = index.delete_documents(id)
          client.wait_for_task(task['taskUid'])
        end.to(change { index.documents['results'].size }.by(-1))
        expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
      end

      it 'deletes documents based on filter from index (with delete route)' do
        expect do
          index.update_filterable_attributes(['objectId'])
          task = index.delete_documents({ filter: ['objectId > 0'] })

          client.wait_for_task(task['taskUid'])
        end.to(change { index.documents['results'].size }.by(-documents.size))
      end

      it 'ignores filter even when documents_ids is empty (with delete-batch route)' do
        expect do
          task = index.delete_documents({ filter: ['objectId > 0'] })

          client.wait_for_task(task['taskUid'])
        end.to(change { index.documents['results'].size }.by(0))
      end

      it 'deletes one document synchronously from index (with delete-batch route)' do
        id = 2
        expect do
          task = index.delete_documents(id, wait: true)

          expect(task['status']).not_to eql('enqueued')
          expect(task['status']).to eql('succeeded')
        end.to(change { index.documents['results'].size }.by(-1))
        expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
      end

      it 'deletes one document from index (with delete-batch route as an array of one uid)' do
        id = 123
        expect do
          task = index.delete_documents([id])
          client.wait_for_task(task['taskUid'])
        end.to(change { index.documents['results'].size }.by(-1))
        expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
      end

      it 'deletes one document synchronously from index (with delete-batch route as an array of one uid)' do
        id = 123
        expect do
          task = index.delete_documents([id], wait: true)

          expect(task['status']).not_to eql('enqueued')
          expect(task['status']).to eql('succeeded')
        end.to(change { index.documents['results'].size }.by(-1))
        expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
      end

      it 'deletes multiples documents from index' do
        docs_to_delete = [1, 4]
        expect do
          task = index.delete_documents(docs_to_delete)
          client.wait_for_task(task['taskUid'])
        end.to(change { index.documents['results'].size }.by(-2))
      end

      it 'deletes multiples documents synchronously from index' do
        docs_to_delete = [1, 4]
        expect do
          task = index.delete_documents(docs_to_delete, wait: true)

          expect(task['status']).not_to eql('enqueued')
          expect(task['status']).to eql('succeeded')
        end.to(change { index.documents['results'].size }.by(-2))
      end

      it 'clears all documents from index' do
        expect do
          task = index.delete_all_documents
          client.wait_for_task(task['taskUid'])
          expect(index.documents['results']).to be_empty
        end.to(change { index.documents['results'].size }.from(documents.size).to(0))
      end

      it 'clears all documents synchronously from index' do
        task = index.delete_all_documents(wait: true)

        expect(task).to have_key('status')
        expect(task['status']).not_to eql('enqueued')
        expect(task['status']).to eql('succeeded')
        expect(index.documents['results']).to be_empty
        expect(index.documents['results'].size).to eq(0)
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
      task = index.add_documents(documents, 'unique')
      expect(task).to be_a(Hash)
      client.wait_for_task(task['taskUid'])
      expect(index.fetch_primary_key).to eq('unique')
    end

    it 'does not take into account the new primary key' do
      index.add_documents(documents, 'unique', wait: true)
      task = index.update_documents({
                                      unique: 3,
                                      id: 1,
                                      title: 'The Red and the Black'
                                    }, 'id')

      task = client.wait_for_task(task['taskUid'])

      expect(task['status']).to eq('failed')
      expect(task['type']).to eq('documentAdditionOrUpdate')
      expect(task['error']['code']).to eq('index_primary_key_already_exists')
    end
  end

  context 'Wrong primary-key (attribute does not exist) when pushing documents' do
    let(:documents) do
      { unique: 3, id: 1, title: 'Le Rouge et le Noir' }
    end

    it 'does not add the primary key and the documents either' do
      task = index.update_documents(documents, 'objectId')
      client.wait_for_task(task['taskUid'])
      expect(index.fetch_primary_key).to be_nil
      expect(index.task(task['taskUid'])['status']).to eq('failed')
    end
  end

  context 'Wrong primary-key (attribute bad formatted) when pushing documents' do
    let(:documents) do
      { id: 1, title: 'Le Rouge et le Noir' }
    end

    it 'does not add the primary key and the documents either' do
      task = index.add_documents(documents, 'title')
      client.wait_for_task(task['taskUid'])
      expect(index.fetch_primary_key).to be_nil
      expect(index.task(task['taskUid'])['status']).to eq('failed')
      expect(index.documents['results'].count).to eq(0)
    end
  end

  context 'Impossible to infer the primary-key' do
    let(:documents) do
      { title: 'Le Rouge et le Noir' }
    end

    it 'Impossible to push docs if the pk is missing' do
      task = index.add_documents(documents, wait: true)
      update = index.task(task['uid'])
      expect(update['status']).to eq('failed')
      expect(update['error']['code']).to eq('index_primary_key_no_candidate_found')
    end
  end

  context 'Impossible to update primary-key if already given during index creation' do
    let(:documents) do
      { id: 1, unique: 1, title: 'Le Rouge et le Noir' }
    end

    it 'adds the documents anyway' do
      task = index.add_documents(documents, 'unique')
      expect(task).to be_a(Hash)
      client.wait_for_task(task['taskUid'])
      expect(index.fetch_primary_key).to eq('unique')
      expect(index.documents['results'].count).to eq(1)
    end
  end
end
