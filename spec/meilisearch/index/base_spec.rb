# frozen_string_literal: true

RSpec.describe MeiliSearch::Index do
  before(:all) do
    @uid1 = 'UID_1'
    @uid2 = 'UID_2'
    @primary_key = 'objectId'
    client = MeiliSearch::Client.new($URL, $MASTER_KEY)
    clear_all_indexes(client)
    @index1 = client.create_index(@uid1)
    @index2 = client.create_index(@uid2, primaryKey: @primary_key)
  end

  it 'shows the index' do
    response = @index1.show
    expect(response).to be_a(Hash)
    expect(response['name']).to eq(@uid1)
    expect(response['uid']).to eq(@uid1)
    expect(response['uid']).to eq(@index1.uid)
    expect(response['primaryKey']).to be_nil
  end

  it 'get primary-key of index if null' do
    expect(@index1.primary_key).to be_nil
  end

  it 'get primary-key of index if it exists' do
    expect(@index2.primary_key).to eq(@primary_key)
  end

  it 'get uid of index' do
    expect(@index1.uid).to eq(@uid1)
  end

  it 'updates primary-key of index if not defined before' do
    new_primary_key = 'id_test'
    response = @index1.update(primaryKey: new_primary_key)
    expect(response).to be_a(Hash)
    expect(response['uid']).to eq(@uid1)
    expect(@index1.primary_key).to eq(new_primary_key)
  end

  it 'returns error if trying to update primary-key if it is already defined' do
    new_primary_key = 'id_test'
    expect do
      @index2.update(primaryKey: new_primary_key)
    end.to raise_bad_request_meilisearch_api_error
    # temporary, will be raise a 'primary_key_already_present' code in the next MS release
  end

  it 'deletes index' do
    expect(@index1.delete).to be_nil
    expect { @index1.show }.to raise_index_not_found_meilisearch_api_error
    expect(@index2.delete).to be_nil
    expect { @index2.show }.to raise_index_not_found_meilisearch_api_error
  end

  it 'fails to manipulate index object after deletion' do
    expect { @index2.primary_key }.to raise_index_not_found_meilisearch_api_error
    expect { @index2.show }.to raise_index_not_found_meilisearch_api_error
    expect { @index2.update(primaryKey: 'id_test') }.to raise_index_not_found_meilisearch_api_error
    expect { @index2.delete }.to raise_index_not_found_meilisearch_api_error
  end

  it 'works with method aliases' do
    expect(@index1.method(:show) == @index1.method(:show_index)).to be_truthy
    expect(@index1.method(:primary_key) == @index1.method(:get_primary_key)).to be_truthy
    expect(@index1.method(:update) == @index1.method(:update_index)).to be_truthy
    expect(@index1.method(:delete) == @index1.method(:delete_index)).to be_truthy
  end
end
