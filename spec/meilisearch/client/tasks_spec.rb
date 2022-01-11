# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Tasks' do
  include_context 'search books with genre'

  let(:enqueued_task_keys) { ['uid', 'indexUid', 'status', 'type', 'enqueuedAt'] }
  let(:succeeded_task_keys) { [*enqueued_task_keys, 'details', 'duration', 'startedAt', 'finishedAt'] }
  let!(:doc_addition_task) { index.add_documents!(documents) }
  let(:task_uid) { doc_addition_task['uid'] }

  it 'gets a task of an index' do
    task = index.task(task_uid)

    expect(task.keys).to include(*succeeded_task_keys)
  end

  it 'gets all the tasks of an index' do
    tasks = index.tasks

    expect(tasks['results']).to be_a(Array)

    last_task = tasks['results'].first

    expect(last_task.keys).to include(*succeeded_task_keys)
  end

  it 'gets a task of the MeiliSearch instance' do
    task = client.task(0)

    expect(task).to be_a(Hash)
    expect(task['uid']).to eq(0)
    expect(task.keys).to include(*succeeded_task_keys)
  end

  it 'gets all the tasks of the MeiliSearch instance' do
    tasks = client.tasks

    expect(tasks['results']).to be_a(Array)

    last_task = tasks['results'].first

    expect(last_task.keys).to include(*succeeded_task_keys)
  end

  describe '#index.wait_for_task' do
    it 'waits for task with default values' do
      task = index.add_documents(documents)
      task = index.wait_for_task(task['uid'])

      expect(task).to be_a(Hash)
      expect(task['status']).not_to eq('enqueued')
    end

    it 'waits for task with default values after several updates' do
      5.times { index.add_documents(documents) }
      task = index.add_documents(documents)
      status = index.wait_for_task(task['uid'])

      expect(status).to be_a(Hash)
      expect(status['status']).not_to eq('enqueued')
    end

    it 'waits for task with custom timeout_in_ms and raises MeiliSearchTimeoutError' do
      index.add_documents(documents)
      task = index.add_documents(documents)
      expect do
        index.wait_for_task(task['uid'], 1)
      end.to raise_error(MeiliSearch::TimeoutError)
    end

    it 'waits for task with custom interval_in_ms and raises Timeout::Error' do
      index.add_documents(documents)
      task = index.add_documents(documents)
      expect do
        Timeout.timeout(0.1) do
          index.wait_for_task(task['uid'], 5000, 200)
        end
      end.to raise_error(Timeout::Error)
    end
  end

  describe '#client.wait_for_task' do
    it 'waits for task with default values' do
      task = index.add_documents!(documents)
      task = client.wait_for_task(task['uid'])

      expect(task).to be_a(Hash)
      expect(task['status']).not_to eq('enqueued')
    end

    it 'waits for task with default values after several updates' do
      5.times { index.add_documents(documents) }
      task = index.add_documents(documents)
      status = client.wait_for_task(task['uid'])

      expect(status).to be_a(Hash)
      expect(status['status']).not_to eq('enqueued')
    end

    it 'waits for task with custom timeout_in_ms and raises MeiliSearchTimeoutError' do
      index.add_documents(documents)
      task = index.add_documents(documents)
      expect do
        client.wait_for_task(task['uid'], 1)
      end.to raise_error(MeiliSearch::TimeoutError)
    end

    it 'waits for task with custom interval_in_ms and raises Timeout::Error' do
      index.add_documents(documents)
      task = index.add_documents(documents)
      expect do
        Timeout.timeout(0.1) do
          client.wait_for_task(task['uid'], 5000, 200)
        end
      end.to raise_error(Timeout::Error)
    end
  end
end
