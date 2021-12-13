# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Tasks' do
  include_context 'search books with genre'

  # Ensure there is at least 1 task
  before do
    task = index.add_documents!(documents)
    @task_uid = task['uid']
  end

  it 'gets a task of an index' do
    task = index.task(@task_uid)
    expect(task).to be_a(Hash)
    expect(task['uid']).to eq(@task_uid)
    expect(task).to have_key('status')
    expect(task).to have_key('indexUid')
    expect(task).to have_key('type')
  end

  it 'gets all the tasks of an index' do
    tasks = index.tasks
    expect(tasks['results']).to be_a(Array)
    expect(tasks['results'].first).to have_key('uid')
    expect(tasks['results'].first).to have_key('status')
    expect(tasks['results'].first).to have_key('indexUid')
    expect(tasks['results'].first).to have_key('type')
  end

  it 'gets a task of the MeiliSearch instance' do
    task = client.task(0)
    expect(task).to be_a(Hash)
    expect(task['uid']).to eq(0)
    expect(task).to have_key('status')
    expect(task).to have_key('indexUid')
    expect(task).to have_key('type')
  end

  it 'gets all the tasks of the MeiliSearch instance' do
    tasks = client.tasks
    expect(tasks['results']).to be_a(Array)
    expect(tasks['results'].first).to have_key('uid')
    expect(tasks['results'].first).to have_key('status')
    expect(tasks['results'].first).to have_key('indexUid')
    expect(tasks['results'].first).to have_key('type')
  end

  it 'waits for pending update with default values' do
    task = index.add_documents!(documents)
    expect(task).to be_a(Hash)
    expect(task['status']).not_to eq('enqueued')
  end

  it 'waits for pending update with default values after several updates' do
    index.add_documents(documents)
    index.add_documents(documents)
    index.add_documents(documents)
    index.add_documents(documents)
    index.add_documents(documents)
    task = index.add_documents(documents)
    status = index.wait_for_task(task['uid'])
    expect(status).to be_a(Hash)
    expect(status['status']).not_to eq('enqueued')
  end

  it 'waits for pending update with custom timeout_in_ms and raises MeiliSearchTimeoutError' do
    index.add_documents(documents)
    task = index.add_documents(documents)
    expect do
      index.wait_for_task(task['uid'], 1)
    end.to raise_error(MeiliSearch::TimeoutError)
  end

  it 'waits for pending update with custom interval_in_ms and raises Timeout::Error' do
    index.add_documents(documents)
    task = index.add_documents(documents)
    expect do
      Timeout.timeout(0.1) do
        index.wait_for_task(task['uid'], 5000, 200)
      end
    end.to raise_error(Timeout::Error)
  end
end
