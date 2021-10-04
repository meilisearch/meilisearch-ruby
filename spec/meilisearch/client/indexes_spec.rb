# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Indexes' do
  it 'creates an index without primary-key' do
    index = test_client.create_index('index')
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq('index')
    expect(index.primary_key).to be_nil
    expect(index.fetch_primary_key).to be_nil
  end

  it 'creates an index with primary-key' do
    index = test_client.create_index('index', primaryKey: 'primary_key')
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq('index')
    expect(index.primary_key).to eq('primary_key')
    expect(index.fetch_primary_key).to eq('primary_key')
  end

  it 'creates an index with uid in options - should not take it into account' do
    index = test_client.create_index('index', primaryKey: 'primary_key', uid: 'wrong')
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq('index')
    expect(index.primary_key).to eq('primary_key')
    expect(index.fetch_primary_key).to eq('primary_key')
  end

  it 'creates an new index with get_or_create_index method' do
    expect do
      index = test_client.get_or_create_index('index')

      expect(index).to be_a(MeiliSearch::Index)
      expect(index.uid).to eq('index')
      expect(index.primary_key).to be_nil
    end.to(change { test_client.indexes.length }.by(1))

    fetched_index = test_client.fetch_index('index')
    expect(fetched_index.uid).to eq('index')
    expect(fetched_index.primary_key).to be_nil
  end

  it 'creates an new index with get_or_create_index method and a primary-key' do
    expect do
      index = test_client.get_or_create_index('index', primaryKey: 'title')

      expect(index).to be_a(MeiliSearch::Index)
      expect(index.uid).to eq('index')
      expect(index.primary_key).to eq('title')
    end.to(change { test_client.indexes.length }.by(1))

    fetched_index = test_client.fetch_index('index')
    expect(fetched_index.uid).to eq('index')
    expect(fetched_index.primary_key).to eq('title')
  end

  it 'get an already existing index with get_or_create_index method' do
    expect do
      index = test_client.get_or_create_index(test_uid)

      expect(index).to be_a(MeiliSearch::Index)
      expect(index.uid).to eq(test_uid)
      expect(index.primary_key).to be_nil
    end.not_to(change { test_client.indexes.length })
  end

  it 'fails to create an index with an uid already taken' do
    expect do
      test_client.create_index(test_uid)
    end.to raise_meilisearch_api_error_with(400, 'index_already_exists', 'invalid_request_error')
  end

  it 'fails to create an index with bad UID format' do
    expect do
      test_client.create_index('two words')
    end.to raise_meilisearch_api_error_with(400, 'invalid_index_uid', 'invalid_request_error')
  end

  it 'gets list of indexes' do
    # test_index is the first index
    test_client.create_index('second_index')
    test_client.create_index('third_index')

    indexes = test_client.indexes

    expect(indexes).to be_a(Array)
    expect(indexes.length).to eq(3)
    uids = indexes.map { |elem| elem['uid'] }
    expect(uids).to contain_exactly(test_uid, 'second_index', 'third_index')
  end

  it 'fetch a specific index' do
    test_client.create_index('specific_index', primaryKey: 'primary_key')

    response = test_client.fetch_index('specific_index')

    expect(response).to be_a(MeiliSearch::Index)
    expect(response.uid).to eq('specific_index')
    expect(response.primary_key).to eq('primary_key')
    expect(response.fetch_primary_key).to eq('primary_key')
  end

  it 'returns an index object based on uid' do
    test_client.create_index('index_with_pk', primaryKey: 'primary_key')

    index = test_client.index('index_with_pk')

    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq('index_with_pk')
    expect(index.primary_key).to be_nil
    expect(index.fetch_primary_key).to eq('primary_key')
    expect(index.primary_key).to eq('primary_key')
  end

  it 'deletes index' do
    # test_index is the first index
    expect do
      test_client.create_index('another_index')
    end.to(change { test_client.indexes.length }.from(1).to(2))

    expect do
      expect(test_client.delete_index('another_index')).to be_nil
    end.to(change { test_client.indexes.length }.from(2).to(1))
  end

  context 'with snake_case options' do
    it 'creates an index without errors' do
      uid = SecureRandom.uuid

      expect do
        @client.create_index(uid, primary_key: @primary_key)
        @client.fetch_index(uid)
      end.to_not raise_error
    end
  end
end
