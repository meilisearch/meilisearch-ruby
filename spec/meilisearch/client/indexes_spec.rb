# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Indexes' do
  describe '#create_index' do
    context 'without a primary key' do
      it 'creates an index' do
        task = client.create_index('new_index')
        expect(task['type']).to eq('indexCreation')
        client.wait_for_task(task['uid'])

        index = client.fetch_index('new_index')
        expect(index).to be_a(MeiliSearch::Index)
        expect(index.uid).to eq('new_index')
        expect(index.primary_key).to be_nil
      end

      it 'creates an index synchronously' do
        task = client.create_index!('new_index')
        expect(task['type']).to eq('indexCreation')
        expect(task['status']).to eq('succeeded')

        index = client.fetch_index('new_index')
        expect(index).to be_a(MeiliSearch::Index)
        expect(index.uid).to eq('new_index')
        expect(index.primary_key).to be_nil
      end
    end

    context 'with a primary key' do
      it 'creates an index' do
        task = client.create_index('new_index', primaryKey: 'primary_key')
        expect(task['type']).to eq('indexCreation')
        client.wait_for_task(task['uid'])

        index = client.fetch_index('new_index')
        expect(index).to be_a(MeiliSearch::Index)
        expect(index.uid).to eq('new_index')
        expect(index.primary_key).to eq('primary_key')
        expect(index.fetch_primary_key).to eq('primary_key')
      end

      it 'creates an index synchronously' do
        task = client.create_index!('new_index', primaryKey: 'primary_key')
        expect(task['type']).to eq('indexCreation')
        expect(task['status']).to eq('succeeded')

        index = client.fetch_index('new_index')
        expect(index).to be_a(MeiliSearch::Index)
        expect(index.uid).to eq('new_index')
        expect(index.primary_key).to eq('primary_key')
        expect(index.fetch_primary_key).to eq('primary_key')
      end

      context 'when primary key option in snake_case' do
        it 'creates an index' do
          task = client.create_index('new_index', primary_key: 'primary_key')
          expect(task['type']).to eq('indexCreation')
          client.wait_for_task(task['uid'])

          index = client.fetch_index('new_index')
          expect(index).to be_a(MeiliSearch::Index)
          expect(index.uid).to eq('new_index')
          expect(index.primary_key).to eq('primary_key')
          expect(index.fetch_primary_key).to eq('primary_key')
        end
      end

      context 'when uid is provided as an option' do
        it 'ignores the uid option' do
          task = client.create_index(
            'new_index',
            primaryKey: 'primary_key',
            uid: 'not_primary_key'
          )
          expect(task['type']).to eq('indexCreation')
          client.wait_for_task(task['uid'])

          index = client.fetch_index('new_index')
          expect(index).to be_a(MeiliSearch::Index)
          expect(index.uid).to eq('new_index')
          expect(index.primary_key).to eq('primary_key')
          expect(index.fetch_primary_key).to eq('primary_key')
        end
      end
    end

    context 'when an index with a given uid already exists' do
      it 'returns a failing task' do
        task1 = client.create_index!('existing_index')
        task2 = client.create_index!('existing_index')
        expect(task1['type']).to eq('indexCreation')
        expect(task2['type']).to eq('indexCreation')
        expect(task1['status']).to eq('succeeded')
        expect(task2['status']).to eq('failed')
        expect(task2['error']['code']).to eq('index_already_exists')
      end
    end

    context 'when the uid format is invalid' do
      it 'raises an error' do
        expect do
          client.create_index('two words')
        end.to raise_meilisearch_api_error_with(400, 'invalid_index_uid', 'invalid_request')
      end
    end
  end

  # describe '#get_or_create_index' do
  #   it 'creates a new index' do
  #     expect do
  #       new_index = client.get_or_create_index('new_index')

  #       expect(new_index).to be_a(MeiliSearch::Index)
  #     end.to change { client.indexes.length }.by(1)

  #     found_index = client.fetch_index('new_index')
  #     expect(found_index.uid).to eq('new_index')
  #     expect(found_index.primary_key).to be_nil
  #   end

  #   it 'gets an index that already exists' do
  #     client.create_index('existing_index')

  #     expect do
  #       client.get_or_create_index('existing_index')
  #     end.not_to(change { client.indexes.length })
  #   end

  #   context 'when a primary key is provided' do
  #     it 'creates a new index' do
  #       expect do
  #         index = client.get_or_create_index('new_index', primaryKey: 'primary_key')

  #         expect(index).to be_a(MeiliSearch::Index)
  #       end.to change { client.indexes.length }.by(1)
  #     end
  #   end
  # end

  describe '#indexes' do
    it 'returns MeiliSearch::Index objects' do
      client.create_index!('index')
      index = client.indexes.first
      expect(index).to be_a(MeiliSearch::Index)
    end

    it 'gets a list of indexes' do
      ['first_index', 'second_index', 'third_index'].each { |name| client.create_index!(name) }

      indexes = client.indexes

      expect(indexes).to be_a(Array)
      expect(indexes.length).to eq(3)
      uids = indexes.map(&:uid)
      expect(uids).to contain_exactly('first_index', 'second_index', 'third_index')
    end
  end

  describe '#raw_indexes' do
    it 'returns raw indexes' do
      client.create_index!('index')

      response = client.raw_indexes.first

      expect(response).to be_a(Hash)
      expect(response['uid']).to eq('index')
    end

    it 'gets a list of raw indexes' do
      ['first_index', 'second_index', 'third_index'].each { |name| client.create_index!(name) }

      indexes = client.raw_indexes

      expect(indexes).to be_a(Array)
      expect(indexes.length).to eq(3)
      uids = indexes.map { |elem| elem['uid'] }
      expect(uids).to contain_exactly('first_index', 'second_index', 'third_index')
    end
  end

  describe '#fetch_index' do
    it 'fetches index by uid' do
      client.create_index!('new_index', primaryKey: 'primary_key')

      fetched_index = client.fetch_index('new_index')

      expect(fetched_index).to be_a(MeiliSearch::Index)
      expect(fetched_index.uid).to eq('new_index')
      expect(fetched_index.primary_key).to eq('primary_key')
      expect(fetched_index.fetch_primary_key).to eq('primary_key')
    end
  end

  describe '#fetch_raw_index' do
    it 'fetch a specific index raw Hash response based on uid' do
      client.create_index!('specific_index_fetch_raw', primaryKey: 'primary_key')

      index = client.fetch_index('specific_index_fetch_raw')
      raw_response = index.fetch_raw_info

      expect(raw_response).to be_a(Hash)
      expect(raw_response['uid']).to eq('specific_index_fetch_raw')
      expect(raw_response['primaryKey']).to eq('primary_key')
      expect(Time.parse(raw_response['createdAt'])).to be_a(Time)
      expect(Time.parse(raw_response['createdAt'])).to be_within(60).of(Time.now)
      expect(Time.parse(raw_response['updatedAt'])).to be_a(Time)
      expect(Time.parse(raw_response['updatedAt'])).to be_within(60).of(Time.now)
    end
  end

  describe '#index' do
    it 'returns an index object with the provided uid' do
      client.create_index!('existing_index', primaryKey: 'primary_key')

      # this index is in memory, without metadata from server
      index = client.index('existing_index')

      expect(index).to be_a(MeiliSearch::Index)
      expect(index.uid).to eq('existing_index')
      expect(index.primary_key).to be_nil

      # fetch primary key metadata from server
      expect(index.fetch_primary_key).to eq('primary_key')
      expect(index.primary_key).to eq('primary_key')
    end
  end

  describe '#delete_index' do
    context 'when the index exists' do
      it 'deletes the index' do
        client.create_index!('existing_index')

        task = client.delete_index('existing_index')
        expect(task['type']).to eq('indexDeletion')
        achieved_task = client.wait_for_task(task['uid'])

        expect(achieved_task['status']).to eq('succeeded')
        expect { client.fetch_index('existing_index') }.to raise_index_not_found_meilisearch_api_error
      end
    end

    context 'when the index does not exist' do
      it 'raises an index not found error' do
        expect { client.fetch_index('index_does_not_exist') }.to raise_index_not_found_meilisearch_api_error
      end
    end
  end
end
