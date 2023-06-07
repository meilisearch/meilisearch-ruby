# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Tasks' do
  include_context 'search books with genre'

  let(:enqueued_task_keys) { ['uid', 'indexUid', 'status', 'type', 'enqueuedAt'] }
  let(:succeeded_task_keys) { [*enqueued_task_keys, 'details', 'duration', 'startedAt', 'finishedAt'] }
  let!(:doc_addition_task) { index.add_documents(documents, wait: true) }
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

  it 'gets a task of the Meilisearch instance' do
    task = client.task(0)

    expect(task).to be_a(Hash)
    expect(task['uid']).to eq(0)
    expect(task.keys).to include(*succeeded_task_keys)
  end

  it 'gets tasks of the Meilisearch instance' do
    tasks = client.tasks

    expect(tasks['results']).to be_a(Array)

    last_task = tasks['results'].first

    expect(last_task.keys).to include(*succeeded_task_keys)
  end

  it 'paginates tasks with limit/from/next' do
    tasks = client.tasks(limit: 2)

    expect(tasks['results'].count).to be <= 2
    expect(tasks['from']).to be_a(Integer)
    expect(tasks['next']).to be_a(Integer)
  end

  it 'filters tasks with index_uids/types/statuses' do
    tasks = client.tasks(index_uids: ['a-cool-index-name'])

    expect(tasks['results'].count).to eq(0)

    tasks = client.tasks(index_uids: ['books'], types: ['documentAdditionOrUpdate'], statuses: ['succeeded'])

    expect(tasks['results'].count).to be > 1
  end

  it 'ensures supports to all available filters' do
    allow(MeiliSearch::Utils).to receive(:transform_attributes).and_call_original

    client.tasks(
      canceled_by: [1, 2], uids: [2], foo: 'bar',
      before_enqueued_at: '2022-01-20', after_enqueued_at: '2022-01-20',
      before_started_at: '2022-01-20', after_started_at: '2022-01-20',
      before_finished_at: '2022-01-20', after_finished_at: '2022-01-20'
    )

    expect(MeiliSearch::Utils).to have_received(:transform_attributes)
      .with(
        canceled_by: [1, 2], uids: [2],
        before_enqueued_at: '2022-01-20', after_enqueued_at: '2022-01-20',
        before_started_at: '2022-01-20', after_started_at: '2022-01-20',
        before_finished_at: '2022-01-20', after_finished_at: '2022-01-20'
      )
  end

  describe '#index.wait_for_task' do
    it 'waits for task with default values' do
      task = index.add_documents(documents)
      task = index.wait_for_task(task['taskUid'])

      expect(task).to be_a(Hash)
      expect(task['status']).not_to eq('enqueued')
    end

    it 'waits for task with default values after several updates' do
      5.times { index.add_documents(documents) }
      task = index.add_documents(documents)
      status = index.wait_for_task(task['taskUid'])

      expect(status).to be_a(Hash)
      expect(status['status']).not_to eq('enqueued')
    end

    it 'waits for task with custom timeout_in_ms and raises MeiliSearchTimeoutError' do
      index.add_documents(documents)
      task = index.add_documents(documents)
      expect do
        index.wait_for_task(task['taskUid'], 1)
      end.to raise_error(MeiliSearch::TimeoutError)
    end

    it 'waits for task with custom interval_in_ms and raises Timeout::Error' do
      index.add_documents(documents)
      task = index.add_documents(documents)
      expect do
        Timeout.timeout(0.1) do
          index.wait_for_task(task['taskUid'], 5000, 200)
        end
      end.to raise_error(Timeout::Error)
    end
  end

  describe '#client.wait_for_task' do
    it 'waits for task with default values' do
      task = index.add_documents(documents, wait: true)
      task = client.wait_for_task(task['taskUid'])

      expect(task).to be_a(Hash)
      expect(task['status']).not_to eq('enqueued')
    end

    it 'waits for task with default values after several updates' do
      5.times { index.add_documents(documents) }
      task = index.add_documents(documents)
      status = client.wait_for_task(task['taskUid'])

      expect(status).to be_a(Hash)
      expect(status['status']).not_to eq('enqueued')
    end

    it 'waits for task with custom timeout_in_ms and raises MeiliSearchTimeoutError' do
      index.add_documents(documents)
      task = index.add_documents(documents)
      expect do
        client.wait_for_task(task['taskUid'], 1)
      end.to raise_error(MeiliSearch::TimeoutError)
    end

    it 'waits for task with custom interval_in_ms and raises Timeout::Error' do
      index.add_documents(documents)
      task = index.add_documents(documents)
      expect do
        Timeout.timeout(0.1) do
          client.wait_for_task(task['taskUid'], 5000, 200)
        end
      end.to raise_error(Timeout::Error)
    end
  end

  describe '#client.cancel_tasks' do
    it 'ensures supports to all available filters' do
      allow(MeiliSearch::Utils).to receive(:transform_attributes).and_call_original

      client.cancel_tasks(
        canceled_by: [1, 2], uids: [2], foo: 'bar',
        before_enqueued_at: '2022-01-20', after_enqueued_at: '2022-01-20',
        before_started_at: '2022-01-20', after_started_at: '2022-01-20',
        before_finished_at: '2022-01-20', after_finished_at: '2022-01-20'
      )

      expect(MeiliSearch::Utils).to have_received(:transform_attributes)
        .with(
          canceled_by: [1, 2], uids: [2],
          before_enqueued_at: '2022-01-20', after_enqueued_at: '2022-01-20',
          before_started_at: '2022-01-20', after_started_at: '2022-01-20',
          before_finished_at: '2022-01-20', after_finished_at: '2022-01-20'
        )
    end

    it 'has fields in the details field' do
      task = client.cancel_tasks(uids: [1, 2])
      task = client.wait_for_task(task['taskUid'])

      expect(task['details']['originalFilter']).to eq('?uids=1%2C2')
      expect(task['details']['matchedTasks']).to be_a(Integer)
      expect(task['details']['canceledTasks']).to be_a(Integer)
    end
  end

  describe '#client.delete_tasks' do
    it 'ensures supports to all available filters' do
      date = DateTime.new(2022, 1, 20)

      allow(MeiliSearch::Utils).to receive(:transform_attributes).and_call_original

      client.delete_tasks(
        canceled_by: [1, 2], uids: [2], foo: 'bar',
        before_enqueued_at: date, after_enqueued_at: date,
        before_started_at: date, after_started_at: date,
        before_finished_at: date, after_finished_at: date
      )

      expect(MeiliSearch::Utils).to have_received(:transform_attributes)
        .with(
          canceled_by: [1, 2], uids: [2],
          before_enqueued_at: date, after_enqueued_at: date,
          before_started_at: date, after_started_at: date,
          before_finished_at: date, after_finished_at: date
        )
    end

    it 'has fields in the details field' do
      task = client.delete_tasks(uids: [1, 2])
      task = client.wait_for_task(task['taskUid'])

      expect(task['details']['originalFilter']).to eq('?uids=1%2C2')
      expect(task['details']['matchedTasks']).to be_a(Integer)
      expect(task['details']['deletedTasks']).to be_a(Integer)
    end
  end
end
