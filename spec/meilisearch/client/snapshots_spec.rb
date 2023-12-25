# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Snapshots' do
  it 'creates a new snapshot' do
    response = client.create_snapshot
    expect(response).to be_a(Hash)
    expect(response['taskUid']).to_not be_nil
    expect(response['status']).to_not be_nil
    expect(response['status']).to eq('enqueued')
    response = client.wait_for_task(response['taskUid'])
    expect(response['status']).to eq('succeeded')
  end
end
