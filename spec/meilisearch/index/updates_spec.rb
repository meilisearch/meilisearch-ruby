# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Updates' do
  include_context 'search books with genre'

  it 'gets an empty array when nothing happened before' do
    index = test_client.create_index('new_index')
    response = index.get_all_update_status
    expect(response).to be_a(Array)
    expect(response).to be_empty
  end

  it 'gets update status after adding documents' do
    response = index.add_documents(documents)
    update_id = response['updateId']
    index.wait_for_pending_update(update_id)
    response = index.get_update_status(update_id)
    expect(response).to be_a(Hash)
    expect(response['updateId']).to eq(update_id)
    expect(response['status']).to eq('processed')
    expect(response['type']).to be_a(Hash)
  end

  it 'gets all the update status' do
    response = index.get_all_update_status
    expect(response).to be_a(Array)
    expect(response.count).to eq(1)
  end

  it 'achieved_upate? method returns true' do
    boolean = index.achieved_upate?(index.get_update_status(0))
    expect(boolean).to be_truthy
  end

  it 'waits for pending update with default values' do
    response = index.add_documents(documents)
    update_id = response['updateId']
    status = index.wait_for_pending_update(update_id)
    expect(status).to be_a(Hash)
    expect(status['status']).not_to eq('enqueued')
  end

  it 'waits for pending update with default values after several updates' do
    index.add_documents(documents)
    index.add_documents(documents)
    index.add_documents(documents)
    index.add_documents(documents)
    index.add_documents(documents)
    response = index.add_documents(documents)
    update_id = response['updateId']
    status = index.wait_for_pending_update(update_id)
    expect(status).to be_a(Hash)
    expect(status['status']).not_to eq('enqueued')
  end

  it 'waits for pending update with custom timeout_in_ms and raises MeiliSearchTimeoutError' do
    index.add_documents(documents)
    response = index.add_documents(documents)
    update_id = response['updateId']
    expect do
      index.wait_for_pending_update(update_id, 1)
    end.to raise_error(MeiliSearch::TimeoutError)
  end

  it 'waits for pending update with custom interval_in_ms and raises Timeout::Error' do
    index.add_documents(documents)
    response = index.add_documents(documents)
    update_id = response['updateId']
    expect do
      Timeout.timeout(0.1) do
        index.wait_for_pending_update(update_id, 5000, 200)
      end
    end.to raise_error(Timeout::Error)
  end
end
