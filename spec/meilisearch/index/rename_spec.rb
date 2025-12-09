# frozen_string_literal: true

RSpec.describe Meilisearch::Index, '- Rename' do
  it 'renames an existing index' do
    client.create_index('uid').await
    index = client.fetch_index('uid')

    task = client.index('uid').update(uid: 'uid_renamed')
    expect(task.type).to eq('indexUpdate')
    task.await

    renamed_index = client.fetch_index('uid_renamed')
    expect(renamed_index).to be_a(described_class)
    expect(renamed_index.uid).to eq('uid_renamed')
    expect(renamed_index.created_at).to be_a(Time).and eq(index.created_at)
    expect(renamed_index.updated_at).to be_a(Time).and be_within(60).of(Time.now)
    expect { client.fetch_index('uid') }.to raise_index_not_found_meilisearch_api_error
  end

  it 'returns a failing task if the target uid already exists' do
    client.create_index('uid').await
    client.create_index('books').await

    task = client.index('uid').update(uid: 'books')
    expect(task.type).to eq('indexUpdate')

    task.await
    expect(task).to be_failed
    expect(task.error['code']).to eq('index_already_exists')
  end

  it 'returns a failed task for non-existent index' do
    task = client.index('uid').update(uid: 'uid_renamed')
    expect(task.type).to eq('indexUpdate')

    task.await
    expect(task).to be_failed
    expect(task.error['code']).to eq('index_not_found')
  end

  it 'fails when the uid format is invalid' do
    client.create_index('uid').await
    index = client.fetch_index('uid')

    expect do
      index.update(uid: 'Invalid UID!')
    end.to raise_meilisearch_api_error_with(400, 'invalid_index_uid', 'invalid_request')
  end

  it 'renames an index that already contains documents' do
    index = client.index('uid')
    index.add_documents(id: 1, title: 'My Title').await

    task = client.index('uid').update(uid: 'uid_renamed')
    expect(task.type).to eq('indexUpdate')
    task.await

    renamed_index = client.fetch_index('uid_renamed')
    expect(renamed_index).to be_a(described_class)
    expect(renamed_index.uid).to eq('uid_renamed')
    expect(renamed_index.documents['results'].size).to eq(1)
  end

  it 'renames an index and updates its primary key' do
    client.create_index('uid', primary_key: 'id').await

    task = client.index('uid').update(uid: 'uid_renamed', primary_key: 'id_renamed')
    expect(task.type).to eq('indexUpdate')
    task.await

    renamed_index = client.fetch_index('uid_renamed')
    expect(renamed_index).to be_a(described_class)
    expect(renamed_index.uid).to eq('uid_renamed')
    expect(renamed_index.primary_key).to eq('id_renamed')
  end

  it 'renames an index and keeps its stats intact' do
    index = client.index('uid')
    index.add_documents(id: 1, title: 'My Title').await
    stats = index.stats

    task = client.index('uid').update(uid: 'uid_renamed')
    expect(task.type).to eq('indexUpdate')
    task.await

    renamed_index_stats = client.fetch_index('uid_renamed').stats
    expect(renamed_index_stats).to include('numberOfDocuments' => stats['numberOfDocuments'])
  end

  it 'renames an index and keeps its settings intact' do
    index = client.index('uid')
    index.update_settings(distinct_attribute: 'title', stop_words: ['the']).await
    settings = index.settings

    task = client.index('uid').update(uid: 'uid_renamed')
    expect(task.type).to eq('indexUpdate')
    task.await

    renamed_index_settings = client.fetch_index('uid_renamed').settings
    expect(renamed_index_settings).to include(
      'distinctAttribute' => settings['distinctAttribute'],
      'stopWords' => settings['stopWords']
    )
  end
end
