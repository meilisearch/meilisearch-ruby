# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Dumps' do
  it 'creates a new dump' do
    response = client.create_dump
    expect(response).to be_a(Hash)
    expect(response['taskUid']).to_not be_nil
    expect(response['status']).to_not be_nil
    expect(response['status']).to eq('enqueued')
    response = client.wait_for_task(response['taskUid'])
    expect(response['status']).to eq('succeeded')
  end
end
