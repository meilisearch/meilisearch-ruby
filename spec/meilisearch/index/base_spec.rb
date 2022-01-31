# frozen_string_literal: true

RSpec.describe MeiliSearch::Index do
  it 'fetch the info of the index' do
    client.create_index!('new_index')

    index = client.fetch_index('new_index')
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq('new_index')
    expect(index.created_at).to be_a(Time)
    expect(index.created_at).to be_within(60).of(Time.now)
    expect(index.updated_at).to be_a(Time)
    expect(index.created_at).to be_within(60).of(Time.now)
    expect(index.primary_key).to be_nil
  end

  it 'fetch the raw Hash info of the index' do
    client.create_index!('specific_index_fetch_raw', primaryKey: 'primary_key')

    raw_index = client.fetch_raw_index('specific_index_fetch_raw')

    expect(raw_index).to be_a(Hash)
    expect(raw_index['uid']).to eq('specific_index_fetch_raw')
    expect(raw_index['primaryKey']).to eq('primary_key')
    expect(Time.parse(raw_index['createdAt'])).to be_a(Time)
    expect(Time.parse(raw_index['createdAt'])).to be_within(60).of(Time.now)
    expect(Time.parse(raw_index['updatedAt'])).to be_a(Time)
    expect(Time.parse(raw_index['updatedAt'])).to be_within(60).of(Time.now)
  end

  it 'get primary-key of index if null' do
    client.create_index!('index_without_primary_key')

    index = client.fetch_index('index_without_primary_key')
    expect(index.primary_key).to be_nil
    expect(index.fetch_primary_key).to be_nil
  end

  it 'get primary-key of index if it exists' do
    client.create_index!('index_with_prirmary_key', primaryKey: 'primary_key')

    index = client.fetch_index('index_with_prirmary_key')
    expect(index.primary_key).to eq('primary_key')
    expect(index.fetch_primary_key).to eq('primary_key')
  end

  it 'get uid of index' do
    client.create_index!('uid')

    index = client.fetch_index('uid')
    expect(index.uid).to eq('uid')
  end

  it 'updates primary-key of index if not defined before' do
    client.create_index!('uid')

    task = client.index('uid').update(primaryKey: 'new_primary_key')
    expect(task['type']).to eq('indexUpdate')
    client.wait_for_task(task['uid'])

    index = client.fetch_index('uid')
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq('uid')
    expect(index.primary_key).to eq('new_primary_key')
    expect(index.fetch_primary_key).to eq('new_primary_key')
    expect(index.created_at).to be_a(Time)
    expect(index.created_at).to be_within(60).of(Time.now)
    expect(index.updated_at).to be_a(Time)
    expect(index.updated_at).to be_within(60).of(Time.now)
  end

  it 'updates primary-key of index if has been defined before but there is not docs' do
    client.create_index!('uid', primaryKey: 'primary_key')

    task = client.index('uid').update(primaryKey: 'new_primary_key')
    expect(task['type']).to eq('indexUpdate')
    client.wait_for_task(task['uid'])

    index = client.fetch_index('uid')
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq('uid')
    expect(index.primary_key).to eq('new_primary_key')
    expect(index.fetch_primary_key).to eq('new_primary_key')
    expect(index.created_at).to be_a(Time)
    expect(index.created_at).to be_within(60).of(Time.now)
    expect(index.updated_at).to be_a(Time)
    expect(index.updated_at).to be_within(60).of(Time.now)
  end

  it 'returns a failing task if primary-key is already defined' do
    index = client.index('uid')
    index.add_documents!({ id: 1, title: 'My Title' })

    task = index.update(primaryKey: 'new_primary_key')
    expect(task['type']).to eq('indexUpdate')
    achieved_task = client.wait_for_task(task['uid'])

    expect(achieved_task['status']).to eq('failed')
    expect(achieved_task['error']['code']).to eq('index_primary_key_already_exists')
  end

  it 'supports options' do
    options = { timeout: 2, max_retries: 1 }
    expected_headers = {
      'Authorization' => "Bearer #{MASTER_KEY}",
      'User-Agent' => MeiliSearch.qualified_version
    }

    new_client = MeiliSearch::Client.new(URL, MASTER_KEY, options)
    new_client.create_index!('options')
    index = new_client.fetch_index('options')
    expect(index.options).to eq({ max_retries: 1, timeout: 2, convert_body?: true })

    expect(MeiliSearch::Index).to receive(:get).with(
      "#{URL}/indexes/options",
      {
        headers: expected_headers,
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
    client.create_index!('uid')

    task = client.index('uid').delete
    expect(task['type']).to eq('indexDeletion')
    achieved_task = client.wait_for_task(task['uid'])
    expect(achieved_task['status']).to eq('succeeded')
    expect { client.fetch_index('uid') }.to raise_index_not_found_meilisearch_api_error
  end

  it 'fails to manipulate index object after deletion' do
    client.create_index!('uid')

    task = client.index('uid').delete
    expect(task['type']).to eq('indexDeletion')
    client.wait_for_task(task['uid'])

    index = client.index('uid')
    expect { index.fetch_primary_key }.to raise_index_not_found_meilisearch_api_error
    expect { index.fetch_info }.to raise_index_not_found_meilisearch_api_error
  end

  it 'works with method aliases' do
    client.create_index!('uid', primaryKey: 'primary_key')

    index = client.fetch_index('uid')
    expect(index.method(:fetch_primary_key) == index.method(:get_primary_key)).to be_truthy
    expect(index.method(:update) == index.method(:update_index)).to be_truthy
    expect(index.method(:delete) == index.method(:delete_index)).to be_truthy
  end

  context 'with snake_case options' do
    it 'does the request with camelCase attributes' do
      client.create_index!('uid')

      task = client.index('uid').update(primary_key: 'new_primary_key')
      expect(task['type']).to eq('indexUpdate')
      client.wait_for_task(task['uid'])

      index = client.fetch_index('uid')
      expect(index).to be_a(MeiliSearch::Index)
      expect(index.uid).to eq('uid')
      expect(index.primary_key).to eq('new_primary_key')
      expect(index.fetch_primary_key).to eq('new_primary_key')
    end
  end
end
