# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Tasks' do
  include_context 'search books with genre'

  it 'gets an empty array when nothing happened before' do
    tasks = client.tasks
    expect(tasks).to be_a(Array)
    expect(tasks).to be_empty
  end

  it 'gets a task of an index' do
    task = index.add_documents(documents)
    task_uid = task['uid']
    index.wait_for_pending_task(task_uid)
    task = index.task(task_uid)
    expect(task).to be_a(Hash)
    expect(task['uid']).to eq(task_uid)
    expect(task['status']).to eq('succeeded')
    expect(task['type']).to be_a('documentsAddition')
  end

  it 'gets all the tasks of an index' do
    tasks = index.tasks
    expect(tasks).to be_a(Array)
    expect(tasks.count).to eq(1)
  end

  it 'gets a task of the MeiliSearch instance' do
    task = client.task(task_uid)
    expect(task).to be_a(Hash)
    expect(task['uid']).to eq(task_uid)
    expect(task['status']).to eq('succeeded')
    expect(task['type']).to be_a('documentsAddition')
  end

  it 'gets all the tasks of the MeiliSearch instance' do
    tasks = client.tasks
    expect(tasks).to be_a(Array)
    expect(tasks.count).to eq(1)
  end

  it 'achieved_task? method returns true' do
    boolean = index.achieved_task?(index.task(0))
    expect(boolean).to be_truthy
  end

  it 'waits for pending update with default values' do
    task = index.add_documents(documents)
    status = index.wait_for_pending_task(task['uid'])
    expect(status).to be_a(Hash)
    expect(status['status']).not_to eq('enqueued')
  end

  it 'waits for pending update with default values after several updates' do
    index.add_documents(documents)
    index.add_documents(documents)
    index.add_documents(documents)
    index.add_documents(documents)
    index.add_documents(documents)
    task = index.add_documents(documents)
    status = index.wait_for_pending_task(task['uid'])
    expect(status).to be_a(Hash)
    expect(status['status']).not_to eq('enqueued')
  end

  it 'waits for pending update with custom timeout_in_ms and raises MeiliSearchTimeoutError' do
    index.add_documents(documents)
    task = index.add_documents(documents)
    expect do
      index.wait_for_pending_task(task['uid'], 1)
    end.to raise_error(MeiliSearch::TimeoutError)
  end

  it 'waits for pending update with custom interval_in_ms and raises Timeout::Error' do
    index.add_documents(documents)
    task = index.add_documents(documents)
    expect do
      Timeout.timeout(0.1) do
        index.wait_for_pending_task(task['uid'], 5000, 200)
      end
    end.to raise_error(Timeout::Error)
  end
end
