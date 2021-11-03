# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Dumps' do
  it 'creates a new dump' do
    response = client.create_dump
    expect(response).to be_a(Hash)
    expect(response['uid']).to_not be_nil
    expect(response['status']).to_not be_nil
    expect(response['status']).to eq('in_progress')
    wait_for_dump_creation(client, response['uid'])
  end

  it 'gets dump status' do
    dump = client.create_dump
    response = client.dump_status(dump['uid'])
    expect(response['status']).to_not be_nil
    wait_for_dump_creation(client, dump['uid'])
  end

  it 'fails to get dump status without uid' do
    expect do
      client.dump_status('uid_not_exists')
    end.to raise_meilisearch_api_error_with(404, 'not_found', 'invalid_request')
  end

  it 'works with method aliases' do
    expect(client.method(:dump_status) == client.method(:get_dump_status)).to be_truthy
  end
end
