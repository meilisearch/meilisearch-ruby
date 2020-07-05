# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Indexes' do
  before(:all) do
    @client = MeiliSearch::Client.new($URL, $MASTER_KEY)
    clear_all_indexes(@client)
    @uid1 = 'uid1'
    @uid2 = 'uid2'
    @uid3 = 'uid3'
    @primary_key = 'objectId'
  end

  it 'creates an index without primary-key' do
    index = @client.create_index(@uid1)
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq(@uid1)
    expect(index.primary_key).to be_nil
  end

  it 'creates an index with primary-key' do
    index = @client.create_index(@uid2, primaryKey: @primary_key)
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq(@uid2)
    expect(index.primary_key).to eq(@primary_key)
  end

  it 'creates an index with uid in options - should not take it into account' do
    index = @client.create_index(@uid3, primaryKey: @primary_key, uid: 'wrong')
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq(@uid3)
    expect(index.primary_key).to eq(@primary_key)
  end

  it 'fails to create an index with an uid already taken' do
    expect do
      @client.create_index(@uid1)
    end.to raise_meilisearch_api_error_with(400)
  end

  it 'fails to create an index with bad UID format' do
    expect do
      @client.create_index('two words')
    end.to raise_meilisearch_api_error_with(400)
  end

  it 'gets list of indexes' do
    response = @client.indexes
    expect(response).to be_a(Array)
    expect(response.count).to eq(3)
    uids = response.map { |elem| elem['uid'] }
    expect(uids).to contain_exactly(@uid1, @uid2, @uid3)
  end

  it 'shows a specific index' do
    response = @client.show_index(@uid2)
    expect(response).to be_a(Hash)
    expect(response['uid']).to eq(@uid2)
    expect(response['primaryKey']).to eq(@primary_key)
  end

  it 'returns an index object based on uid' do
    index = @client.index(@uid2)
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq(@uid2)
    expect(index.primary_key).to eq(@primary_key)
  end

  it 'deletes index' do
    expect(@client.delete_index(@uid1)).to be_nil
    expect { @client.show_index(@uid1) }.to raise_meilisearch_api_error_with(404)
    expect(@client.delete_index(@uid2)).to be_nil
    expect { @client.show_index(@uid2) }.to raise_meilisearch_api_error_with(404)
    expect(@client.delete_index(@uid3)).to be_nil
    expect { @client.show_index(@uid3) }.to raise_meilisearch_api_error_with(404)
    expect(@client.indexes.count).to eq(0)
  end

  it 'works with method aliases' do
    expect(@client.method(:index) == @client.method(:get_index)).to be_truthy
  end
end
