# frozen_string_literal: true

RSpec.describe MeiliSearch::Index do
  it 'fetch the info of the index' do
    client.create_index('books', wait: true)

    index = client.fetch_index('books')
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq('books')
    expect(index.created_at).to be_a(Time)
    expect(index.created_at).to be_within(60).of(Time.now)
    expect(index.updated_at).to be_a(Time)
    expect(index.created_at).to be_within(60).of(Time.now)
    expect(index.primary_key).to be_nil
  end

  it 'fetch the raw Hash info of the index' do
    client.create_index('books', primaryKey: 'reference_number', wait: true)

    raw_index = client.fetch_raw_index('books')

    expect(raw_index).to be_a(Hash)
    expect(raw_index['uid']).to eq('books')
    expect(raw_index['primaryKey']).to eq('reference_number')
    expect(Time.parse(raw_index['createdAt'])).to be_a(Time)
    expect(Time.parse(raw_index['createdAt'])).to be_within(60).of(Time.now)
    expect(Time.parse(raw_index['updatedAt'])).to be_a(Time)
    expect(Time.parse(raw_index['updatedAt'])).to be_within(60).of(Time.now)
  end

  it 'get primary-key of index if null' do
    client.create_index('index_without_primary_key', wait: true)

    index = client.fetch_index('index_without_primary_key')
    expect(index.primary_key).to be_nil
    expect(index.fetch_primary_key).to be_nil
  end

  it 'get primary-key of index if it exists' do
    client.create_index('index_with_prirmary_key', primaryKey: 'primary_key', wait: true)

    index = client.fetch_index('index_with_prirmary_key')
    expect(index.primary_key).to eq('primary_key')
    expect(index.fetch_primary_key).to eq('primary_key')
  end

  it 'get uid of index' do
    client.create_index('uid', wait: true)

    index = client.fetch_index('uid')
    expect(index.uid).to eq('uid')
  end

  it 'updates primary-key of index if not defined before' do
    client.create_index('uid', wait: true)

    task = client.index('uid').update(primaryKey: 'new_primary_key')
    expect(task['type']).to eq('indexUpdate')
    client.wait_for_task(task['taskUid'])

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
    client.create_index('books', primaryKey: 'reference_number', wait: true)

    task = client.index('books').update(primaryKey: 'international_standard_book_number')
    expect(task['type']).to eq('indexUpdate')
    client.wait_for_task(task['taskUid'])

    index = client.fetch_index('books')
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.uid).to eq('books')
    expect(index.primary_key).to eq('international_standard_book_number')
    expect(index.fetch_primary_key).to eq('international_standard_book_number')
    expect(index.created_at).to be_a(Time)
    expect(index.created_at).to be_within(60).of(Time.now)
    expect(index.updated_at).to be_a(Time)
    expect(index.updated_at).to be_within(60).of(Time.now)
  end

  it 'returns a failing task if primary-key is already defined' do
    index = client.index('uid')
    index.add_documents({ id: 1, title: 'My Title' }, wait: true)

    task = index.update(primaryKey: 'new_primary_key')
    expect(task['type']).to eq('indexUpdate')
    achieved_task = client.wait_for_task(task['taskUid'])

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
    new_client.create_index('books', wait: true)
    index = new_client.fetch_index('books')
    expect(index.options).to eq({ max_retries: 1, timeout: 2, convert_body?: true })

    expect(MeiliSearch::Index).to receive(:get).with(
      "#{URL}/indexes/books",
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

  it 'supports client_agents' do
    custom_agent = 'Meilisearch Rails (v0.0.1)'
    options = { timeout: 2, max_retries: 1, client_agents: [custom_agent] }
    expected_headers = {
      'Authorization' => "Bearer #{MASTER_KEY}",
      'User-Agent' => "#{custom_agent};#{MeiliSearch.qualified_version}"
    }

    new_client = MeiliSearch::Client.new(URL, MASTER_KEY, options)
    new_client.create_index('books', wait: true)
    index = new_client.fetch_index('books')
    expect(index.options).to eq(options.merge({ convert_body?: true }))

    expect(MeiliSearch::Index).to receive(:get).with(
      "#{URL}/indexes/books",
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
    client.create_index('uid', wait: true)

    task = client.index('uid').delete
    expect(task['type']).to eq('indexDeletion')
    achieved_task = client.wait_for_task(task['taskUid'])
    expect(achieved_task['status']).to eq('succeeded')
    expect { client.fetch_index('uid') }.to raise_index_not_found_meilisearch_api_error
  end

  it 'fails to manipulate index object after deletion' do
    client.create_index('uid', wait: true)

    task = client.index('uid').delete
    expect(task['type']).to eq('indexDeletion')
    client.wait_for_task(task['taskUid'])

    index = client.index('uid')
    expect { index.fetch_primary_key }.to raise_index_not_found_meilisearch_api_error
    expect { index.fetch_info }.to raise_index_not_found_meilisearch_api_error
  end

  it 'works with method aliases' do
    client.create_index('uid', primaryKey: 'primary_key', wait: true)

    index = client.fetch_index('uid')
    expect(index.method(:fetch_primary_key) == index.method(:get_primary_key)).to be_truthy
    expect(index.method(:update) == index.method(:update_index)).to be_truthy
    expect(index.method(:delete) == index.method(:delete_index)).to be_truthy
  end

  context 'with snake_case options' do
    it 'does the request with camelCase attributes' do
      client.create_index('uid', wait: true)

      task = client.index('uid').update(primary_key: 'new_primary_key')
      expect(task['type']).to eq('indexUpdate')
      client.wait_for_task(task['taskUid'])

      index = client.fetch_index('uid')
      expect(index).to be_a(MeiliSearch::Index)
      expect(index.uid).to eq('uid')
      expect(index.primary_key).to eq('new_primary_key')
      expect(index.fetch_primary_key).to eq('new_primary_key')
    end
  end
end
