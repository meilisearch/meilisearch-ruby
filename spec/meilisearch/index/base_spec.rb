# frozen_string_literal: true

RSpec.describe MeiliSearch::Index do
  it 'fetch the info of the index' do
    index = client.create_index('new_index')
    index.fetch_info
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq('new_index')
    expect(index.created_at).to be_a(Time)
    expect(index.created_at).to be_within(60).of(Time.now)
    expect(index.updated_at).to be_a(Time)
    expect(index.created_at).to be_within(60).of(Time.now)
    expect(index.primary_key).to be_nil
  end

  it 'get primary-key of index if null' do
    index = client.create_index('index_without_primary_key')
    expect(index.primary_key).to be_nil
    expect(index.fetch_primary_key).to be_nil
  end

  it 'get primary-key of index if it exists' do
    index = client.create_index('index_with_prirmary_key', primaryKey: 'primary_key')
    expect(index.primary_key).to eq('primary_key')
    expect(index.fetch_primary_key).to eq('primary_key')
  end

  it 'get uid of index' do
    index = client.create_index('uid')
    expect(index.uid).to eq('uid')
  end

  it 'updates primary-key of index if not defined before' do
    index = client.create_index('uid')
    index.update(primaryKey: 'new_primary_key')
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq('uid')
    expect(index.primary_key).to eq('new_primary_key')
    expect(index.fetch_primary_key).to eq('new_primary_key')
    expect(index.created_at).to be_a(Time)
    expect(index.created_at).to be_within(60).of(Time.now)
    expect(index.updated_at).to be_a(Time)
    expect(index.updated_at).to be_within(60).of(Time.now)
  end

  it 'returns error if trying to update primary-key if it is already defined' do
    index = client.create_index('uid', primaryKey: 'primary_key')
    expect do
      index.update(primaryKey: 'new_primary_key')
    end.to raise_meilisearch_api_error_with(
      400,
      'primary_key_already_present',
      'invalid_request_error'
    )
  end

  it 'supports options' do
    options = { timeout: 2, max_retries: 1 }
    new_client = MeiliSearch::Client.new(URL, MASTER_KEY, options)
    index = new_client.create_index('options')
    expect(index.options).to eq({ timeout: 2, max_retries: 1 })
    expect(MeiliSearch::Index).to receive(:get).with(
      "#{URL}/indexes/options",
      {
        headers: { 'X-Meili-API-Key' => MASTER_KEY },
        body: 'null',
        query: {},
        max_retries: 1,
        timeout: 2
      }
    ).and_return(double(success?: true,
                        parsed_response: { 'createdAt' => '2021-10-16T14:57:35Z',
                                           'updatedAt' => '2021-10-16T14:57:35Z' }))
    index.fetch_info
  end

  it 'deletes index' do
    index = client.create_index('uid')
    expect(index.delete).to be_nil
    expect { index.fetch_info }.to raise_index_not_found_meilisearch_api_error
  end

  it 'fails to manipulate index object after deletion' do
    index = client.create_index('uid')
    expect(index.delete).to be_nil

    expect { index.fetch_primary_key }.to raise_index_not_found_meilisearch_api_error
    expect { index.fetch_info }.to raise_index_not_found_meilisearch_api_error
    expect { index.update(primaryKey: 'new_primary_key') }.to raise_index_not_found_meilisearch_api_error
    expect { index.delete }.to raise_index_not_found_meilisearch_api_error
  end

  it 'works with method aliases' do
    index = client.create_index('uid', primaryKey: 'primary_key')

    expect(index.method(:fetch_primary_key) == index.method(:get_primary_key)).to be_truthy
    expect(index.method(:update) == index.method(:update_index)).to be_truthy
    expect(index.method(:delete) == index.method(:delete_index)).to be_truthy
  end
end
