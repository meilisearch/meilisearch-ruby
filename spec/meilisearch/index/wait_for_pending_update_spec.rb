# frozen_string_literal: true

RSpec.describe MeiliSearch::Index do
  before(:all) do
    @documents = [
      { objectId: 123,  title: 'Pride and Prejudice' },
      { objectId: 456,  title: 'Le Petit Prince' },
      { objectId: 1,    title: 'Alice In Wonderland' },
      { objectId: 1344, title: 'The Hobbit' },
      { objectId: 4,    title: 'Harry Potter and the Half-Blood Prince' },
      { objectId: 42,   title: 'The Hitchhiker\'s Guide to the Galaxy' }
    ]
    client = MeiliSearch::Client.new($URL, $MASTER_KEY)
    clear_all_indexes(client)
    @index = client.create_index(uid: 'books', primaryKey: 'objectId')
  end

  it 'waits for pending update with default values' do
    response = @index.add_documents(@documents)
    update_id = response['updateId']
    status = @index.wait_for_pending_update(update_id)
    expect(status).to be_a(Hash)
    expect(status['status']).not_to eq('enqueued')
  end

  it 'waits for pending update with default values after several updates' do
    @index.add_documents(@documents)
    @index.add_documents(@documents)
    @index.add_documents(@documents)
    @index.add_documents(@documents)
    @index.add_documents(@documents)
    response = @index.add_documents(@documents)
    update_id = response['updateId']
    status = @index.wait_for_pending_update(update_id)
    expect(status).to be_a(Hash)
    expect(status['status']).not_to eq('enqueued')
  end

  it 'waits for pending update with custom timeout_in_ms and raises MeiliSearchTimeoutError' do
    @index.add_documents(@documents)
    response = @index.add_documents(@documents)
    update_id = response['updateId']
    lambda {
      @index.wait_for_pending_update(update_id, 1)
    }.should raise_error(MeiliSearch::MeiliSearchTimeoutError)
  end

  it 'waits for pending update with custom interval_in_ms and raises Timeout::Error' do
    @index.add_documents(@documents)
    response = @index.add_documents(@documents)
    update_id = response['updateId']
    lambda {
      Timeout.timeout(0.1) do
        @index.wait_for_pending_update(update_id, 5000, 200)
      end
    }.should raise_error(Timeout::Error)
  end
end
