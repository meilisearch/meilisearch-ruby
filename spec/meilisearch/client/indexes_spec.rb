# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Indexes' do
  describe '#create_index' do
    context 'without a primary key' do
      it 'creates an index' do
        task = client.create_index('books')

        expect(task['type']).to eq('indexCreation')

        client.wait_for_task(task['taskUid'])
        index = client.fetch_index('books')

        expect(index).to be_a(MeiliSearch::Index)
        expect(index.uid).to eq('books')
        expect(index.primary_key).to be_nil
      end

      it 'creates an index synchronously' do
        task = client.create_index('books', wait: true)

        expect(task['type']).to eq('indexCreation')
        expect(task['status']).to eq('succeeded')

        index = client.fetch_index('books')

        expect(index).to be_a(MeiliSearch::Index)
        expect(index.uid).to eq('books')
        expect(index.primary_key).to be_nil
      end
    end

    context 'with a primary key' do
      it 'creates an index' do
        task = client.create_index('books', primaryKey: 'reference_code')

        expect(task['type']).to eq('indexCreation')

        client.wait_for_task(task['taskUid'])
        index = client.fetch_index('books')

        expect(index).to be_a(MeiliSearch::Index)
        expect(index.uid).to eq('books')
        expect(index.primary_key).to eq('reference_code')
        expect(index.fetch_primary_key).to eq('reference_code')
      end

      it 'creates an index synchronously' do
        task = client.create_index('books', primaryKey: 'reference_code', wait: true)

        expect(task['type']).to eq('indexCreation')
        expect(task['status']).to eq('succeeded')

        index = client.fetch_index('books')

        expect(index).to be_a(MeiliSearch::Index)
        expect(index.uid).to eq('books')
        expect(index.primary_key).to eq('reference_code')
        expect(index.fetch_primary_key).to eq('reference_code')
      end

      context 'when primary key option in snake_case' do
        it 'creates an index' do
          task = client.create_index('books', primary_key: 'reference_code')
          expect(task['type']).to eq('indexCreation')
          client.wait_for_task(task['taskUid'])

          index = client.fetch_index('books')
          expect(index).to be_a(MeiliSearch::Index)
          expect(index.uid).to eq('books')
          expect(index.primary_key).to eq('reference_code')
          expect(index.fetch_primary_key).to eq('reference_code')
        end
      end

      context 'when uid is provided as an option' do
        it 'ignores the uid option' do
          task = client.create_index(
            'books',
            primaryKey: 'reference_code',
            uid: 'publications'
          )

          expect(task['type']).to eq('indexCreation')

          client.wait_for_task(task['taskUid'])
          index = client.fetch_index('books')

          expect(index).to be_a(MeiliSearch::Index)
          expect(index.uid).to eq('books')
          expect(index.primary_key).to eq('reference_code')
          expect(index.fetch_primary_key).to eq('reference_code')
        end
      end
    end

    context 'when an index with a given uid already exists' do
      it 'returns a failing task' do
        initial_task = client.create_index('books', wait: true)
        last_task = client.create_index('books', wait: true)

        expect(initial_task['type']).to eq('indexCreation')
        expect(last_task['type']).to eq('indexCreation')
        expect(initial_task['status']).to eq('succeeded')
        expect(last_task['status']).to eq('failed')
        expect(last_task['error']['code']).to eq('index_already_exists')
      end
    end

    context 'when the uid format is invalid' do
      it 'raises an error' do
        expect do
          client.create_index('ancient books')
        end.to raise_meilisearch_api_error_with(400, 'invalid_index_uid', 'invalid_request')
      end
    end
  end

  describe '#indexes' do
    it 'returns MeiliSearch::Index objects' do
      client.create_index('books', wait: true)

      index = client.indexes['results'].first

      expect(index).to be_a(MeiliSearch::Index)
    end

    it 'gets a list of indexes' do
      ['books', 'colors', 'artists'].each { |name| client.create_index(name, wait: true) }

      indexes = client.indexes['results']

      expect(indexes).to be_a(Array)
      expect(indexes.length).to eq(3)
      uids = indexes.map(&:uid)
      expect(uids).to contain_exactly('books', 'colors', 'artists')
    end

    it 'paginates indexes list with limit and offset' do
      ['books', 'colors', 'artists'].each { |name| client.create_index(name, wait: true) }

      indexes = client.indexes(limit: 1, offset: 2)

      expect(indexes['results']).to be_a(Array)
      expect(indexes['total']).to eq(3)
      expect(indexes['limit']).to eq(1)
      expect(indexes['offset']).to eq(2)
      expect(indexes['results'].map(&:uid)).to eq(['colors'])
    end
  end

  describe '#raw_indexes' do
    it 'returns raw indexes' do
      client.create_index('index', wait: true)

      response = client.raw_indexes['results'].first

      expect(response).to be_a(Hash)
      expect(response['uid']).to eq('index')
    end

    it 'gets a list of raw indexes' do
      ['books', 'colors', 'artists'].each { |name| client.create_index(name, wait: true) }

      indexes = client.raw_indexes['results']

      expect(indexes).to be_a(Array)
      expect(indexes.length).to eq(3)
      uids = indexes.map { |elem| elem['uid'] }
      expect(uids).to contain_exactly('books', 'colors', 'artists')
    end
  end

  describe '#fetch_index' do
    it 'fetches index by uid' do
      client.create_index('books', primaryKey: 'reference_code', wait: true)

      fetched_index = client.fetch_index('books')

      expect(fetched_index).to be_a(MeiliSearch::Index)
      expect(fetched_index.uid).to eq('books')
      expect(fetched_index.primary_key).to eq('reference_code')
      expect(fetched_index.fetch_primary_key).to eq('reference_code')
    end
  end

  describe '#fetch_raw_index' do
    it 'fetch a specific index raw Hash response based on uid' do
      client.create_index('books', primaryKey: 'reference_code', wait: true)
      index = client.fetch_index('books')
      raw_response = index.fetch_raw_info

      expect(raw_response).to be_a(Hash)
      expect(raw_response['uid']).to eq('books')
      expect(raw_response['primaryKey']).to eq('reference_code')
      expect(Time.parse(raw_response['createdAt'])).to be_a(Time)
      expect(Time.parse(raw_response['createdAt'])).to be_within(60).of(Time.now)
      expect(Time.parse(raw_response['updatedAt'])).to be_a(Time)
      expect(Time.parse(raw_response['updatedAt'])).to be_within(60).of(Time.now)
    end
  end

  describe '#index' do
    it 'returns an index object with the provided uid' do
      client.create_index('books', primaryKey: 'reference_code', wait: true)
      # this index is in memory, without metadata from server
      index = client.index('books')

      expect(index).to be_a(MeiliSearch::Index)
      expect(index.uid).to eq('books')
      expect(index.primary_key).to be_nil

      # fetch primary key metadata from server
      expect(index.fetch_primary_key).to eq('reference_code')
      expect(index.primary_key).to eq('reference_code')
    end
  end

  describe '#delete_index' do
    context 'when the index exists' do
      it 'deletes the index' do
        client.create_index('books', wait: true)
        task = client.delete_index('books')

        expect(task['type']).to eq('indexDeletion')

        achieved_task = client.wait_for_task(task['taskUid'])

        expect(achieved_task['status']).to eq('succeeded')
        expect { client.fetch_index('books') }.to raise_index_not_found_meilisearch_api_error
      end
    end

    context 'when the index does not exist' do
      it 'raises an index not found error' do
        expect { client.fetch_index('books') }.to raise_index_not_found_meilisearch_api_error
      end
    end
  end

  describe '#swap_indexes' do
    it 'swaps two indexes' do
      task = client.swap_indexes(['indexA', 'indexB'], ['indexC', 'indexD'])
      task = client.wait_for_task(task['taskUid'])

      expect(task['type']).to eq('indexSwap')
      expect(task['details']['swaps']).to eq([{ 'indexes' => ['indexA', 'indexB'] },
                                              { 'indexes' => ['indexC', 'indexD'] }])
    end
  end
end
