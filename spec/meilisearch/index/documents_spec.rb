# frozen_string_literal: true

RSpec.describe 'Meilisearch::Index - Documents' do
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

    let(:documents_with_string_keys) { documents.map { |doc| doc.transform_keys(&:to_s) } }

    describe '#add_documents' do
      context 'passed an array of documents' do
        it 'adds documents' do
          task = index.add_documents(documents)
          expect(task.type).to eq('documentAdditionOrUpdate')
          task.await
          expect(index.documents['results']).to contain_exactly(*documents_with_string_keys)
        end

        it 'keeps the structure of the original documents' do
          doc = { object_id: 123, my_title: 'Pride and Prejudice', 'my-comment': 'A great book' }
          index.add_documents([doc]).await

          expect(index.documents['results'].first.keys).to eq(doc.keys.map(&:to_s))
        end

        it 'infers order of fields' do
          index.add_documents(documents).await
          task = index.document(1)
          expect(task.keys).to eq(['objectId', 'title', 'comment'])
        end

        it 'slices response fields' do
          index.add_documents(documents).await

          document = index.document(1, fields: ['title'])

          expect(document.keys).to eq(['title'])
        end

        it 'infers primary-key attribute' do
          index.add_documents(documents).await
          expect(index.fetch_primary_key).to eq('objectId')
        end

        it 'creates the index during document addition' do
          new_index = client.index('books')
          new_index.add_documents(documents).await

          expect(client.index('books').fetch_primary_key).to eq('objectId')
          expect(client.index('books').documents['results'].count).to eq(documents.count)
        end
      end

      it 'adds documents in a batch (as a array of documents)' do
        tasks = index.add_documents_in_batches(documents, 5)
        expect(tasks).to contain_exactly(a_kind_of(Meilisearch::Models::Task),
                                         a_kind_of(Meilisearch::Models::Task))
        tasks.each(&:await)
        expect(index.documents['results']).to contain_exactly(*documents_with_string_keys)
      end


      context 'given a single document' do
        it 'adds only one document to index (as an hash of one document)' do
          new_doc = { objectId: 30, title: 'Hamlet' }
          client.create_index('books').await
          new_index = client.index('books')
          expect do
            new_index.add_documents(new_doc).await
          end.to(change { new_index.documents['results'].length }.by(1))

          expect(new_index.document(30)['title']).to eq('Hamlet')
        end

        it 'fails to add document with bad primary-key format' do
          index.add_documents(documents).await
          task = index.add_documents(objectId: 'toto et titi', title: 'Unknown').await
          expect(task).to have_failed
        end

        it 'fails to add document with no primary-key' do
          index.add_documents(documents).await
          task = index.add_documents(id: 0, title: 'Unknown').await
          expect(task).to have_failed
        end

        it 'allows the user to store vectors' do
          enable_vector_store(true)
          new_doc = { objectId: 123, _vectors: { default: [0.1, 0.2, 0.3] } }
          client.create_index('vector_test').await
          new_index = client.index('vector_test')
          new_index.add_documents(new_doc).await
          expect(new_index.search('123', retrieveVectors: true)['hits'][0]['_vectors']).to include('default')
        end
      end
    end

    describe 'ndjson and csv methods' do
      let(:ndjson_docs) do
        <<~NDJSON
          { "objectRef": 123,  "title": "Pride and Prejudice",                    "comment": "A great book" }
          { "objectRef": 456,  "title": "Le Petit Prince",                        "comment": "A french book" }
          { "objectRef": 4,    "title": "Harry Potter and the Half-Blood Prince", "comment": "The best book" }
          { "objectRef": 55,    "title": "The Three Body Problem", "comment": "An interesting book" }
          { "objectRef": 200,    "title": "Project Hail Mary", "comment": "A lonely book" }
        NDJSON
      end

      let(:json_docs) { "[#{ndjson_docs.rstrip.gsub("\n", ',')}]" }

      let(:csv_docs) do
        <<~CSV
          "objectRef:number","title:string","comment:string"
          "1239","Pride and Prejudice","A great book"
          "456","Le Petit Prince","A french book"
          "49","Harry Potter and the Half-Blood Prince","The best book"
          "55","The Three Body Problem","An interesting book"
          "200","Project Hail Mary","A lonely book"
        CSV
      end

      let(:csv_docs_custom_delim) do
        <<~CSV
          "objectRef:number"|"title:string"|"comment:string"
          "1239"|"Pride and Prejudice"|"A great book"
          "456"|"Le Petit Prince"|"A french book"
          "49"|"Harry Potter and the Half-Blood Prince"|"The best book"
          "55"|"The Three Body Problem"|"An interesting book"
          "200"|"Project Hail Mary"|"A lonely book"
        CSV
      end

      let(:batch1_doc) do
        {
          'objectRef' => 456,
          'title' => 'Le Petit Prince',
          'comment' => 'A french book'
        }
      end

      let(:batch2_doc) do
        {
          'objectRef' => 200,
          'title' => 'Project Hail Mary',
          'comment' => 'A lonely book'
        }
      end

      it '#add_documents_json' do
        index.add_documents_json(json_docs, 'objectRef').await
        expect(index.documents['results'].count).to eq(5)
      end

      it '#add_documents_ndjson' do
        index.add_documents_ndjson(ndjson_docs, 'objectRef').await

        expect(index.documents['results'].count).to eq(5)
        expect(index.documents['results']).to include(batch1_doc, batch2_doc)
      end

      it '#add_documents_csv' do
        index.add_documents_csv(csv_docs, 'objectRef').await
        expect(index.documents['results'].count).to eq(5)
      end

      it '#add_documents_csv with a custom delimiter' do
        index.add_documents_csv(csv_docs_custom_delim, 'objectRef', '|').await

        expect(index.documents['results'].count).to eq(5)
        expect(index.documents['results']).to include(batch1_doc, batch2_doc)
      end

      it '#add_documents_ndjson_in_batches' do
        tasks = index.add_documents_ndjson_in_batches(ndjson_docs, 4, 'objectRef')
        expect(tasks).to contain_exactly(a_kind_of(Meilisearch::Models::Task),
                                         a_kind_of(Meilisearch::Models::Task))
        tasks.each(&:await)
        expect(index.documents['results']).to include(batch1_doc, batch2_doc)
      end

      it '#add_documents_csv_in_batches' do
        tasks = index.add_documents_csv_in_batches(
          csv_docs_custom_delim, 4, 'objectRef', '|'
        )
        expect(tasks).to contain_exactly(a_kind_of(Meilisearch::Models::Task),
                                         a_kind_of(Meilisearch::Models::Task))
        tasks.each(&:await)

        expect(index.documents['results']).to include(batch1_doc, batch2_doc)
      end
    end

    describe '#add_documents!' do
      before { allow(Meilisearch::Utils).to receive(:soft_deprecate).and_return(nil) }

      it 'adds documents synchronously (as an array of documents)' do
        task = index.add_documents!(documents)

        expect(task).to be_finished
        expect(index.documents['results'].count).to eq(documents.count)
      end

      it 'adds only one document synchronously to index (as an hash of one document)' do
        new_doc = { objectId: 30, title: 'Hamlet' }
        client.create_index('books').await
        new_index = client.index('books')
        expect do
          task = new_index.add_documents(new_doc).await

          expect(task).to have_key('status')
          expect(task['status']).to eq('succeeded')
          expect(new_index.document(30)['title']).to eq('Hamlet')
        end.to(change { new_index.documents['results'].length }.by(1))
      end

      it 'warns about deprecation' do
        index.add_documents!(documents)
        expect(Meilisearch::Utils).to have_received(:soft_deprecate)
                                  .with('Index#add_documents!', a_string_including('await'))
      end
    end

    describe '#add_documents_in_batches!' do
      before { allow(Meilisearch::Utils).to receive(:soft_deprecate).and_return(nil) }

      it 'adds document batches synchronously' do
        expect(index.add_documents_in_batches!(documents, 5)).to contain_exactly(be_succeeded, be_succeeded)
        expect(index.documents['results'].count).to eq(documents.count)
      end

      it 'warns about deprecation' do
        index.add_documents_in_batches!(documents, 5)
        expect(Meilisearch::Utils).to have_received(:soft_deprecate)
                                  .with('Index#add_documents_in_batches!', a_string_including('await'))
      end
    end

    describe '#document' do
      before { index.add_documents(documents).await }

      it 'gets one document from its primary-key' do
        expect(index.document(123)).to include(
          'title' => 'Pride and Prejudice',
          'comment' => 'A great book'
        )
      end
    end

    describe '#documents' do
      before do
        index.add_documents(documents).await
        index.update_filterable_attributes(['title', 'objectId']).await
      end

      it 'browses documents' do
        docs = index.documents['results']
        expect(docs).to contain_exactly(*documents_with_string_keys)
      end

      it 'browses documents with query parameters' do
        docs = index.documents(offset: 2, limit: 5)['results']

        expect(docs.size).to eq(5)
        expect(docs.first).to eq(index.documents['results'][2])
      end

      it 'browses documents with fields' do
        docs = index.documents(fields: ['title'])['results']

        expect(docs).to include(a_hash_including('title'))
        expect(docs).not_to include(a_hash_including('comment'))
      end

      it 'retrieves documents by filters' do
        docs = index.documents(filter: 'objectId > 400')['results']

        expect(docs).to include('objectId' => 456,
                                'title' => 'Le Petit Prince',
                                'comment' => 'A french book')
      end

      it 'retrieves documents by filters & other parameters' do
        docs = index.documents(fields: ['title'], filter: 'objectId > 100')['results']

        expect(docs).to contain_exactly(
          { 'title' => a_kind_of(String) },
          { 'title' => a_kind_of(String) },
          { 'title' => a_kind_of(String) }
        )
      end
    end

    describe '#update_documents' do
      before { index.add_documents(documents).await }

      it 'updates multiple documents in index' do
        index.update_documents(
          [{ objectId: 123,  title: 'Sense and Sensibility' },
           { objectId: 456,  title: 'The Little Prince' }]
        ).await

        expect(index.documents['results'].count).to eq(documents.count)
        expect(index.document(123)).to include('objectId' => 123, 'title' => 'Sense and Sensibility')
        expect(index.document(456)).to include('objectId' => 456, 'title' => 'The Little Prince')
      end

      it 'updates a single document in index' do
        index.update_documents({ objectId: 123, title: 'Emma' }).await

        expect(index.documents['results'].count).to eq(documents.count)
        expect(index.document(123)).to include('objectId' => 123, 'title' => 'Emma')
      end

      it 'update a document with new fields' do
        doc = { objectId: 2, note: '8/10' }
        old_title = 'Le Rouge et le Noir'

        index.update_documents(doc).await

        expect(index.documents['results'].count).to eq(documents.count)
        expect(index.document(2)).to include('title' => old_title, 'note' => '8/10')
      end

      it 'replaces document' do
        id = 123
        new_title = 'Pride & Prejudice'
        index.replace_documents(objectId: id, title: 'Pride & Prejudice', note: '8.5/10').await

        expect(index.documents['results'].count).to eq(documents.count)
        doc = index.document(id)
        expect(doc['title']).to eq(new_title)
        expect(doc).not_to have_key('comment')
        expect(doc).to have_key('note')
      end
    end

    describe '#update_documents!' do
      before do
        index.add_documents(documents).await
        allow(Meilisearch::Utils).to receive(:soft_deprecate).and_return(nil)
      end

      it 'updates multiple documents synchronously' do
        updated_documents = [
          { objectId: 123,  title: 'Sense and Sensibility' },
          { objectId: 456,  title: 'The Little Prince' }
        ]

        expect(index.update_documents!(updated_documents)).to be_succeeded

        expect(index.document(123)).to include('objectId' => 123, 'title' => 'Sense and Sensibility')
        expect(index.document(456)).to include('objectId' => 456, 'title' => 'The Little Prince')
      end

      it 'updates a single document synchronously' do
        updated_document = { objectId: 123, title: 'Emma' }

        expect(index.update_documents!(updated_document)).to be_succeeded
        expect(index.document(123)).to include('objectId' => 123, 'title' => 'Emma')
      end

      it 'warns about deprecation' do
        updated_documents = [
          { objectId: 123,  title: 'Sense and Sensibility' },
          { objectId: 456,  title: 'The Little Prince' }
        ]

        index.update_documents!(updated_documents)
        expect(Meilisearch::Utils).to have_received(:soft_deprecate)
                                  .with('Index#update_documents!', a_string_including('await'))
      end
    end

    describe '#update_documents_in_batches' do
      before { index.add_documents(documents).await }

      it 'updates documents in index in batches' do
        updated_documents = [
          { objectId: 123,  title: 'Sense and Sensibility' },
          { objectId: 456,  title: 'The Little Prince' }
        ]

        index.update_documents_in_batches(updated_documents, 1).each(&:await)

        expect(index.document(123)).to include('objectId' => 123, 'title' => 'Sense and Sensibility')
        expect(index.document(456)).to include('objectId' => 456, 'title' => 'The Little Prince')
      end
    end

    describe '#update_documents_in_batches!' do
      before do
        index.add_documents(documents).await
        allow(Meilisearch::Utils).to receive(:soft_deprecate).and_return(nil)
      end

      it 'updates documents synchronously in index in batches (as an array of documents)' do
        updated_documents = [
          { objectId: 123,  title: 'Sense and Sensibility' },
          { objectId: 456,  title: 'The Little Prince' }
        ]

        expect(index.update_documents_in_batches!(updated_documents, 1))
          .to contain_exactly(be_succeeded, be_succeeded)

        expect(index.document(123)).to include('objectId' => 123, 'title' => 'Sense and Sensibility')
        expect(index.document(456)).to include('objectId' => 456, 'title' => 'The Little Prince')
      end

      it 'warns about deprecation' do
        updated_documents = [
          { objectId: 123,  title: 'Sense and Sensibility' },
          { objectId: 456,  title: 'The Little Prince' }
        ]

        index.update_documents_in_batches!(updated_documents, 1)
        expect(Meilisearch::Utils).to have_received(:soft_deprecate)
                                  .with('Index#update_documents_in_batches!', a_string_including('await'))
      end
    end

    describe '#update_documents_by_function' do
      before do
        index.add_documents(documents).await
        index.update_filterable_attributes(['objectId']).await
      end

      it 'updates documents by function' do
        enable_edit_documents_by_function(true)
        expect(index.document(1344)).to include('title' => 'The Hobbit')
        expect(index.document(456)).to include('title' => 'Le Petit Prince')

        index.update_documents_by_function(
          {
            filter: 'objectId = 1344',
            context: { extra: 'extended' },
            function: 'doc.title = `${doc.title.to_upper()} - ${context.extra}`'
          }
        ).await

        expect(index.document(1344)).to include('title' => 'THE HOBBIT - extended')
        expect(index.document(456)).to include('title' => 'Le Petit Prince')
      end
    end

    describe '#delete_document' do
      before { index.add_documents(documents).await }

      it 'if the document id is nil, it raises an error' do
        expect { index.delete_document(nil) }.to raise_error(Meilisearch::InvalidDocumentId)
      end

      it 'deletes one document from index' do
        id = 456
        index.delete_document(id).await

        expect(index.documents['results']).not_to include(a_hash_including('id' => 456))
      end

      it 'does nothing when trying to delete a document which does not exist' do
        id = 111
        expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
        expect do
          index.delete_document(id).await
        end.not_to(change { index.documents['results'].size })
      end
    end

    describe '#delete_document!' do
      before do
        index.add_documents(documents).await
        allow(Meilisearch::Utils).to receive(:soft_deprecate).and_return(nil)
      end

      it 'deletes one document synchronously from index' do
        id = 456
        task = index.delete_document(id).await

        expect(task).to have_key('status')
        expect(task['status']).not_to eql('enqueued')
        expect(task['status']).to eql('succeeded')
        expect(index.documents['results'].size).to eq(documents.count - 1)
        expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
      end

      it 'warns about deprecation' do
        index.delete_document!(2)
        expect(Meilisearch::Utils).to have_received(:soft_deprecate)
                                  .with('Index#delete_document!', a_string_including('await'))
      end
    end

    describe '#delete_documents' do
      before { index.add_documents(documents).await }

      it 'deletes a single document' do
        id = 2
        expect do
          index.delete_documents(id).await
        end.to change { index.documents['results'].size }.by(-1)
        expect { index.document(id) }.to raise_document_not_found_meilisearch_api_error
      end

      it 'deletes documents based on filter from index' do
        index.update_filterable_attributes(['objectId'])
        index.delete_documents(filter: ['objectId > 0']).await
        expect(index.documents['results']).to be_empty
      end

      it 'ignores filters when documents_ids is empty' do
        expect do
          index.delete_documents(filter: ['objectId > 0']).await
        end.not_to(change { index.documents['results'] })
      end

      it 'deletes multiple documents from index' do
        docs_to_delete = [1, 4]
        expect do
          index.delete_documents(docs_to_delete).await
        end.to change { index.documents['results'].size }.by(-2)
      end
    end

    describe '#delete_documents!' do
      before do
        index.add_documents(documents).await
        allow(Meilisearch::Utils).to receive(:soft_deprecate).and_return(nil)
      end

      it 'deletes a single document' do
        id = 2

        expect(index.delete_documents!(id)).to be_succeeded
        expect(index.documents['results']).not_to include(a_hash_including('id' => 2))
      end

      it 'deletes multiple documents' do
        docs_to_delete = [1, 4]
        expect(index.delete_documents!(docs_to_delete)).to be_succeeded

        expect(index.documents['results']).not_to include(
          a_hash_including('id' => 1),
          a_hash_including('id' => 4)
        )
      end

      it 'warns about deprecation' do
        index.delete_documents!([2])
        expect(Meilisearch::Utils).to have_received(:soft_deprecate)
                                  .with('Index#delete_documents!', a_string_including('await'))
      end
    end

    describe '#delete_all_documents' do
      before { index.add_documents(documents).await }

      it 'clears all documents from index' do
        expect(index.documents['results']).not_to be_empty
        index.delete_all_documents.await
        expect(index.documents['results']).to be_empty
      end
    end

    describe '#delete_all_documents!' do
      before do
        index.add_documents(documents).await
        allow(Meilisearch::Utils).to receive(:soft_deprecate).and_return(nil)
      end

      it 'clears all documents synchronously from index' do
        expect(index.documents['results']).not_to be_empty
        expect(index.delete_all_documents!).to be_succeeded
        expect(index.documents['results']).to be_empty
      end

      it 'warns about deprecation' do
        index.delete_all_documents!
        expect(Meilisearch::Utils).to have_received(:soft_deprecate)
                                  .with('Index#delete_all_documents!', a_string_including('await'))
      end
    end

    it 'works with method aliases' do
      expect(index.method(:document)).to eq index.method(:get_document)
      expect(index.method(:document)).to eq index.method(:get_one_document)
      expect(index.method(:documents)).to eq index.method(:get_documents)
      expect(index.method(:add_documents)).to eq index.method(:add_or_replace_documents)
      expect(index.method(:add_documents)).to eq index.method(:replace_documents)
      expect(index.method(:update_documents)).to eq index.method(:add_or_update_documents)
      expect(index.method(:delete_documents)).to eq index.method(:delete_multiple_documents)
      expect(index.method(:delete_document)).to eq index.method(:delete_one_document)
    end
  end

  context 'when the right primary key is passed' do
    let(:documents) do
      [
        { unique: 1, id: 1, title: 'Pride and Prejudice', comment: 'A great book' },
        { unique: 2, id: 1, title: 'Le Petit Prince',     comment: 'A french book' },
        { unique: 3, id: 1, title: 'Le Rouge et le Noir' }
      ]
    end

    it 'adds documents and the primary key' do
      index.add_documents(documents, 'unique').await
      expect(index.fetch_primary_key).to eq('unique')
    end

    it 'fails to add tasks with a different primary key' do
      index.add_documents(documents, 'unique').await
      task = index.update_documents({
                                      unique: 3,
                                      id: 1,
                                      title: 'The Red and the Black'
                                    }, 'id')

      expect(task.await).to be_failed
      expect(task.type).to eq('documentAdditionOrUpdate')
      expect(task.error['code']).to eq('index_primary_key_already_exists')
    end
  end

  context 'when passed a non existant attribute as primary key' do
    let(:documents) do
      { unique: 3, id: 1, title: 'Le Rouge et le Noir' }
    end

    it 'fails to add the documents and the primary key' do
      task = index.update_documents(documents, 'objectId').await
      expect(task).to be_failed
      expect(index.fetch_primary_key).to be_nil
    end
  end

  context 'when the specified primary key field is of an unsupported type' do
    let(:documents) do
      { id: 1, title: 'Le Rouge et le Noir' }
    end

    it 'fails to add the primary key and the documents' do
      task = index.add_documents(documents, 'title').await
      expect(task).to be_failed
      expect(index.fetch_primary_key).to be_nil
      expect(index.documents['results']).to be_empty
    end
  end

  context 'when it is not possible to infer the primary key' do
    let(:documents) do
      { title: 'Le Rouge et le Noir' }
    end

    it 'fails to add documents' do
      task = index.add_documents(documents).await
      expect(task).to be_failed
      expect(task.error['code']).to eq('index_primary_key_no_candidate_found')
    end
  end

  context 'when the primary key was specified on the index' do
    let(:index) do
      uid = random_uid
      client.create_index uid, primary_key: 'id'
      client.index(uid)
    end

    let(:documents) do
      { id: 1, unique: 1, title: 'Le Rouge et le Noir' }
    end

    it 'fails to add documents with another primary key' do
      task = index.add_documents(documents, 'unique')
      task.await
      expect(index.fetch_primary_key).to eq('id')
      expect(index.documents['results']).to be_empty
    end
  end
end
