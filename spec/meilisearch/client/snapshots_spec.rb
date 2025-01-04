# frozen_string_literal: true

RSpec.describe 'Meilisearch::Client - Snapshots' do
  it 'creates a new snapshot' do
    response = client.create_snapshot
    expect(response).to be_a(Hash)
    expect(response['taskUid']).to_not be_nil
    expect(response['status']).to_not be_nil
    expect(response['status']).to eq('enqueued')
    expect(response['type']).to eq('snapshotCreation')
  end
end
