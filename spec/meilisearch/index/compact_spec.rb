# frozen_string_literal: true

RSpec.describe Meilisearch::Index, '- Compact' do
  it 'runs index compaction task' do
    client.create_index('uid').await

    task = client.fetch_index('uid').compact
    expect(task.type).to eq('indexCompaction')

    task.await
    expect(task).to be_succeeded
  end
end
