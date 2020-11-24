# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Indexes' do
  before(:all) do
    @client = MeiliSearch::Client.new($URL, $MASTER_KEY)
    clear_all_indexes(@client)
    @uid1 = 'uid1'
    @uid2 = 'uid2'
    @uid3 = 'uid3'
    @uid4 = 'uid4'
    @uid5 = 'uid5'
    @primary_key = 'objectId'
  end

  it 'creates an index without primary-key' do
    index = @client.create_index(@uid1)
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq(@uid1)
    expect(index.primary_key).to be_nil
    expect(index.fetch_primary_key).to be_nil
  end

  it 'creates an index with primary-key' do
    index = @client.create_index(@uid2, primaryKey: @primary_key)
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq(@uid2)
    expect(index.primary_key).to eq(@primary_key)
    expect(index.fetch_primary_key).to eq(@primary_key)
  end

  it 'creates an index with uid in options - should not take it into account' do
    index = @client.create_index(@uid3, primaryKey: @primary_key, uid: 'wrong')
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq(@uid3)
    expect(index.primary_key).to eq(@primary_key)
    expect(index.fetch_primary_key).to eq(@primary_key)
  end

  it 'creates an new index with get_or_create_index method' do
    index = @client.get_or_create_index(@uid4)
    expect(index).to be_a(MeiliSearch::Index)
    expect(@client.indexes.count).to eq(4)
    expect(@client.fetch_index(@uid4).uid).to eq(index.uid)
    expect(@client.fetch_index(@uid4).uid).to eq(@uid4)
    expect(@client.fetch_index(@uid4).primary_key).to be_nil
    expect(@client.fetch_index(@uid4).primary_key).to eq(index.primary_key)
  end

  it 'creates an new index with get_or_create_index method and a primary-key' do
    index = @client.get_or_create_index(@uid5, primaryKey: 'title')
    expect(index).to be_a(MeiliSearch::Index)
    expect(@client.indexes.count).to eq(5)
    expect(@client.fetch_index(@uid5).uid).to eq(index.uid)
    expect(@client.fetch_index(@uid5).uid).to eq(@uid5)
    expect(@client.fetch_index(@uid5).primary_key).to eq(index.primary_key)
    expect(@client.fetch_index(@uid5).primary_key).to eq('title')
  end

  it 'get an already existing index with get_or_create_index method' do
    index = @client.get_or_create_index(@uid5)
    expect(index).to be_a(MeiliSearch::Index)
    expect(@client.indexes.count).to eq(5)
    expect(@client.fetch_index(@uid5).uid).to eq(index.uid)
    expect(@client.fetch_index(@uid5).uid).to eq(@uid5)
    expect(@client.fetch_index(@uid5).primary_key).to eq('title')
    expect(@client.fetch_index(@uid5).primary_key).to eq(index.primary_key)
  end

  it 'fails to create an index with an uid already taken' do
    expect do
      @client.create_index(@uid1)
    end.to raise_meilisearch_api_error_with(400, 'index_already_exists', 'invalid_request_error')
  end

  it 'fails to create an index with bad UID format' do
    expect do
      @client.create_index('two words')
    end.to raise_meilisearch_api_error_with(400, 'invalid_index_uid', 'invalid_request_error')
  end

  it 'gets list of indexes' do
    response = @client.indexes
    expect(response).to be_a(Array)
    expect(response.count).to eq(5)
    uids = response.map { |elem| elem['uid'] }
    expect(uids).to contain_exactly(@uid1, @uid2, @uid3, @uid4, @uid5)
  end

  it 'fetch a specific index' do
    response = @client.fetch_index(@uid2)
    expect(response).to be_a(MeiliSearch::Index)
    expect(response.uid).to eq(@uid2)
    expect(response.primary_key).to eq(@primary_key)
    expect(response.fetch_primary_key).to eq(@primary_key)
  end

  it 'returns an index object based on uid' do
    index = @client.index(@uid2)
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq(@uid2)
    expect(index.primary_key).to be_nil
    expect(index.fetch_primary_key).to eq(@primary_key)
    expect(index.primary_key).to eq(@primary_key)
  end

  it 'deletes index' do
    expect(@client.delete_index(@uid1)).to be_nil
    expect { @client.fetch_index(@uid1) }.to raise_index_not_found_meilisearch_api_error
    expect(@client.delete_index(@uid2)).to be_nil
    expect { @client.fetch_index(@uid2) }.to raise_index_not_found_meilisearch_api_error
    expect(@client.delete_index(@uid3)).to be_nil
    expect { @client.fetch_index(@uid3) }.to raise_index_not_found_meilisearch_api_error
    expect(@client.delete_index(@uid4)).to be_nil
    expect { @client.fetch_index(@uid4) }.to raise_index_not_found_meilisearch_api_error
    expect(@client.delete_index(@uid5)).to be_nil
    expect { @client.fetch_index(@uid5) }.to raise_index_not_found_meilisearch_api_error
    expect(@client.indexes.count).to eq(0)
  end
end
