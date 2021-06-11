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

  it 'fetch the info of the index' do
    index = @index1.fetch_info
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq(@uid1)
    expect(index.primary_key).to be_nil
  end

  it 'get primary-key of index if null' do
    expect(@index1.primary_key).to be_nil
    expect(@index1.fetch_primary_key).to be_nil
  end

  it 'get primary-key of index if it exists' do
    expect(@index2.primary_key).to eq(@primary_key)
    expect(@index2.fetch_primary_key).to eq(@primary_key)
  end

  it 'get uid of index' do
    expect(@index1.uid).to eq(@uid1)
  end

  it 'updates primary-key of index if not defined before' do
    new_primary_key = 'id_test'
    index = @index1.update(primaryKey: new_primary_key)
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq(@uid1)
    expect(index.primary_key).to eq(new_primary_key)
    expect(index.fetch_primary_key).to eq(new_primary_key)
  end

  it 'returns error if trying to update primary-key if it is already defined' do
    new_primary_key = 'id_test'
    expect do
      @index2.update(primaryKey: new_primary_key)
    end.to raise_meilisearch_api_error_with(
      400,
      'primary_key_already_present',
      'invalid_request_error'
    )
  end

  it 'supports options' do
    options = { timeout: 2, max_retries: 1 }
    client = MeiliSearch::Client.new($URL, $MASTER_KEY, options)
    index_uid = 'options'
    index = client.create_index(index_uid)
    expect(index.options).to eq({ timeout: 2, max_retries: 1 })
    expect(MeiliSearch::Index).to receive(:get).with(
      "#{$URL}/indexes/#{index_uid}",
      {
        headers: { 'Content-Type' => 'application/json', 'X-Meili-API-Key' => $MASTER_KEY },
        body: 'null',
        query: {},
        max_retries: 1,
        timeout: 2
      }
    ).and_return(double(success?: true, parsed_response: ''))
    index.fetch_info
  end

  it 'deletes index' do
    expect(@index1.delete).to be_nil
    expect { @index1.fetch_info }.to raise_index_not_found_meilisearch_api_error
    expect(@index2.delete).to be_nil
    expect { @index2.fetch_info }.to raise_index_not_found_meilisearch_api_error
  end

  it 'fails to manipulate index object after deletion' do
    expect { @index2.fetch_primary_key }.to raise_index_not_found_meilisearch_api_error
    expect { @index2.fetch_info }.to raise_index_not_found_meilisearch_api_error
    expect { @index2.update(primaryKey: 'id_test') }.to raise_index_not_found_meilisearch_api_error
    expect { @index2.delete }.to raise_index_not_found_meilisearch_api_error
  end

  it 'works with method aliases' do
    expect(@index1.method(:fetch_primary_key) == @index1.method(:get_primary_key)).to be_truthy
    expect(@index1.method(:update) == @index1.method(:update_index)).to be_truthy
    expect(@index1.method(:delete) == @index1.method(:delete_index)).to be_truthy
  end
end
