# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Dumps' do
  before(:all) do
    @client = MeiliSearch::Client.new($URL, $MASTER_KEY)
    clear_all_indexes(@client)
  end

  it 'creates a new dump' do
    response = @client.create_dump
    expect(response).to be_a(Hash)
    expect(response['uid']).to_not be_nil
    expect(response['status']).to_not be_nil
    expect(response['status']).to eq('in_progress')
  end

  it 'gets dump status' do
    dump = @client.create_dump
    response = @client.get_dump_status(dump['uid'])
    expect(response['status']).to_not be_nil
  end

  it 'fails to get dump status without uid' do
    expect do
      @client.get_dump_status('uid_not_exists')
    end.to raise_meilisearch_api_error_with(404, 'not_found', 'invalid_request_error')
  end
end
