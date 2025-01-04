# frozen_string_literal: true

describe Meilisearch::Models::Task do
  subject { described_class.new task_hash, endpoint }

  let(:new_index_uid) { random_uid }
  let(:task_hash) { client.http_post '/indexes', { 'uid' => new_index_uid } }
  let(:endpoint) { Meilisearch::Task.new(URL, MASTER_KEY, client.options) }

  let(:enqueued_endpoint) { instance_double(Meilisearch::Task, task: task_hash) }
  let(:enqueued_task) { described_class.new task_hash, enqueued_endpoint }

  let(:processing_endpoint) { instance_double(Meilisearch::Task, task: task_hash.update('status' => 'processing')) }
  let(:processing_task) { described_class.new task_hash, processing_endpoint }

  let(:logger) { instance_double(Logger, warn: nil) }

  before { Meilisearch::Utils.logger = logger }
  after { Meilisearch::Utils.logger = nil }

  describe '.initialize' do
    it 'requires a uid in the task hash' do
      task_hash.delete 'taskUid'

      expect { subject }.to raise_error(ArgumentError)
    end

    it 'requires a type in the task hash' do
      task_hash.delete 'type'

      expect { subject }.to raise_error(ArgumentError)
    end

    it 'requires a status in the task hash' do
      task_hash.delete 'status'

      expect { subject }.to raise_error(ArgumentError)
    end

    it 'sets "taskUid" key when given a "uid"' do
      expect(subject).to have_key('uid')
    end

    it 'sets "uid" key when given a "taskUid"' do
      task_hash['uid'] = task_hash.delete 'taskUid'

      expect(subject).to have_key('taskUid')
    end
  end

  describe 'forwarding' do
    it 'allows accessing values in the internal task hash' do
      subject

      task_hash.each do |key, value|
        expect(subject[key]).to eq(value)
      end
    end
  end

  describe '#enqueued?' do
    context 'when the task is processing' do
      before { task_hash['status'] = 'processing' }

      it { is_expected.not_to be_enqueued }

      it 'does not refresh the task' do
        allow(subject).to receive(:refresh)
        subject.enqueued?
        expect(subject).not_to have_received(:refresh)
      end
    end

    context 'when the task has succeeded' do
      before { task_hash['status'] = 'succeeded' }

      it { is_expected.not_to be_enqueued }

      it 'does not refresh the task' do
        allow(subject).to receive(:refresh)
        subject.enqueued?
        expect(subject).not_to have_received(:refresh)
      end
    end

    context 'when the task has failed' do
      before { task_hash['status'] = 'failed' }

      it { is_expected.not_to be_enqueued }

      it 'does not refresh the task' do
        allow(subject).to receive(:refresh)
        subject.enqueued?
        expect(subject).not_to have_received(:refresh)
      end
    end

    it 'returns true when the task is enqueued' do
      expect(enqueued_task).to be_enqueued
    end

    context 'when the task has succeeded but not refreshed' do
      let(:successful_task_hash) { task_hash.merge('status' => 'succeeded') }
      let(:endpoint) { instance_double(Meilisearch::Task, task: successful_task_hash) }

      it { is_expected.not_to be_enqueued }
    end
  end

  describe '#processing?' do
    context 'when the task has succeeded' do
      before { task_hash['status'] = 'succeeded' }

      it { is_expected.not_to be_processing }

      it 'does not refresh the task' do
        allow(subject).to receive(:refresh)
        subject.processing?
        expect(subject).not_to have_received(:refresh)
      end
    end

    context 'when the task has failed' do
      before { task_hash['status'] = 'failed' }

      it { is_expected.not_to be_processing }

      it 'does not refresh the task' do
        allow(subject).to receive(:refresh)
        subject.processing?
        expect(subject).not_to have_received(:refresh)
      end
    end

    it 'returns false when the task has not begun to process' do
      expect(enqueued_task).not_to be_processing
    end

    it 'returns true when the task is processing' do
      expect(processing_task).to be_processing
    end

    context 'when the task has begun processing but has not refreshed' do
      let(:endpoint) { instance_double(Meilisearch::Task, task: task_hash.merge('status' => 'processing')) }

      it { is_expected.to be_processing }
    end

    context 'when the task has succeeded but not refreshed' do
      let(:successful_task_hash) { task_hash.merge('status' => 'succeeded') }
      let(:endpoint) { instance_double(Meilisearch::Task, task: successful_task_hash) }

      it 'refreshes and returns false' do
        expect(subject).not_to be_enqueued
      end
    end
  end

  describe '#unfinished?' do
    it 'returns false if the task has succeeded' do
      task_hash['status'] = 'succeeded'
      expect(subject).not_to be_unfinished
    end

    it 'returns false when the task has failed' do
      task_hash['status'] = 'failed'
      expect(subject).not_to be_unfinished
    end

    it 'returns true when the task is enqueued' do
      expect(enqueued_task).to be_unfinished
    end

    it 'returns true when the task is processing' do
      expect(processing_task).to be_unfinished
    end

    context 'when the task has succeeded but not refreshed' do
      let(:successful_task_hash) { task_hash.merge('status' => 'succeeded') }
      let(:endpoint) { instance_double(Meilisearch::Task, task: successful_task_hash) }

      it { is_expected.not_to be_unfinished }
    end
  end

  describe '#finished?' do
    it 'returns true when the task has succeeded' do
      task_hash['status'] = 'succeeded'
      expect(subject).to be_finished
    end

    it 'returns true when the task has failed' do
      task_hash['status'] = 'failed'
      expect(subject).to be_finished
    end

    it 'returns false when the task is enqueued' do
      expect(enqueued_task).not_to be_finished
    end

    it 'returns false when the task is processing' do
      expect(processing_task).not_to be_finished
    end

    context 'when the task has succeeded but not refreshed' do
      let(:successful_task_hash) { task_hash.merge('status' => 'succeeded') }
      let(:endpoint) { instance_double(Meilisearch::Task, task: successful_task_hash) }

      it { is_expected.to be_finished }
    end
  end

  describe '#failed?' do
    it 'returns false if the task has succeeded or been cancelled' do
      task_hash['status'] = 'succeeded'
      expect(subject).not_to be_failed
      task_hash['status'] = 'cancelled'
      expect(subject).not_to be_failed
    end

    it 'returns true if the task has failed' do
      task_hash['status'] = 'failed'
      expect(subject).to be_failed
    end

    context 'when the task is not finished' do
      let(:endpoint) { instance_double(Meilisearch::Task, task: task_hash) }

      it { is_expected.not_to be_failed }

      it 'warns that the task is not finished' do
        subject.failed?

        expect(logger).to have_received(:warn).with(a_string_including('checked before finishing'))
      end
    end

    context 'when the task has failed but not refreshed' do
      let(:failed_task_hash) { task_hash.merge('status' => 'failed') }
      let(:endpoint) { instance_double(Meilisearch::Task, task: failed_task_hash) }

      it { is_expected.to be_failed }
    end
  end

  describe '#succeeded?' do
    it 'returns true if the task has succeeded' do
      task_hash['status'] = 'succeeded'
      expect(subject).to be_succeeded
    end

    it 'returns false if the task has failed or been cancelled' do
      task_hash['status'] = 'failed'
      expect(subject).not_to be_succeeded
      task_hash['status'] = 'cancelled'
      expect(subject).not_to be_succeeded
    end

    context 'when the task is not finished' do
      let(:endpoint) { instance_double(Meilisearch::Task, task: task_hash) }

      it { is_expected.not_to be_succeeded }

      it 'warns that the task is not finished' do
        subject.succeeded?

        expect(logger).to have_received(:warn).with(a_string_including('checked before finishing'))
      end
    end

    context 'when the task has succeeded but not refreshed' do
      let(:successful_task_hash) { task_hash.merge('status' => 'succeeded') }
      let(:endpoint) { instance_double(Meilisearch::Task, task: successful_task_hash) }

      it { is_expected.to be_succeeded }
    end
  end

  describe '#cancelled?' do
    it 'returns false if the task has succeeded or failed' do
      task_hash['status'] = 'succeeded'
      expect(subject).not_to be_cancelled
      task_hash['status'] = 'failed'
      expect(subject).not_to be_cancelled
    end

    it 'returns true if the task has been cancelled' do
      task_hash['status'] = 'cancelled'
      expect(subject).to be_cancelled
    end

    context 'when the task is not finished' do
      let(:endpoint) { instance_double(Meilisearch::Task, task: task_hash) }

      it { is_expected.not_to be_cancelled }

      it 'warns that the task is not finished' do
        subject.cancelled?

        expect(logger).to have_received(:warn).with(a_string_including('checked before finishing'))
      end
    end

    context 'when the task has been cancelled but not refreshed' do
      let(:cancelled_task_hash) { task_hash.merge('status' => 'cancelled') }
      let(:endpoint) { instance_double(Meilisearch::Task, task: cancelled_task_hash) }

      it { is_expected.to be_cancelled }
    end
  end

  describe '#deleted?' do
    let(:not_found_error) { Meilisearch::ApiError.new(404, '', '') }
    let(:endpoint) { instance_double(Meilisearch::Task, task: task_hash) }

    it 'returns false when the task can be found' do
      expect(subject.deleted?).to be(false) # don't just return nil
      expect(subject).not_to be_deleted
    end

    context 'when it was deleted prior' do
      let(:endpoint) { instance_double(Meilisearch::Task) }

      before do
        allow(endpoint).to receive(:task) { raise not_found_error }
        subject.refresh
      end

      it 'does not check again' do
        subject.deleted?
        expect(endpoint).to have_received(:task).once
      end

      it { is_expected.to be_deleted }
    end

    it 'refreshes and returns true when it is no longer in instance' do
      allow(endpoint).to receive(:task) { raise not_found_error }
      expect(subject).to be_deleted
    end
  end

  describe '#cancel' do
    context 'when the task is still not finished' do
      let(:cancellation_task) { instance_double(described_class, await: nil) }
      let(:endpoint) { instance_double(Meilisearch::Task, task: task_hash, cancel_tasks: cancellation_task) }

      it 'sends a request to cancel itself' do
        subject.cancel
        expect(endpoint).to have_received(:cancel_tasks)
      end

      it 'returns true when the cancellation succeeds' do
        task_hash['status'] = 'cancelled'
        expect(subject.cancel).to be(true)
      end

      it 'returns false when the cancellation fails' do
        task_hash['status'] = 'succeeded'
        expect(subject.cancel).to be(false)
      end
    end

    context 'when the task is already finished' do
      let(:endpoint) { instance_double(Meilisearch::Task, task: task_hash, cancel_tasks: nil) }

      before { task_hash['status'] = 'succeeded' }

      it 'sends no request' do
        subject.cancel
        expect(endpoint).not_to have_received(:cancel_tasks)
      end

      it { is_expected.not_to be_cancelled }
    end

    context 'when the task is already cancelled' do
      let(:endpoint) { instance_double(Meilisearch::Task, task: task_hash, cancel_tasks: nil) }

      before { task_hash['status'] = 'cancelled' }

      it 'sends no request' do
        subject.cancel
        expect(endpoint).not_to have_received(:cancel_tasks)
      end

      it { is_expected.to be_cancelled }
    end
  end

  describe '#delete' do
    let(:deletion_task) { instance_double(described_class, await: nil) }
    let(:endpoint) { instance_double(Meilisearch::Task, delete_tasks: deletion_task) }

    context 'when the task is unfinished' do
      it 'makes no request' do
        subject.delete
        expect(endpoint).not_to have_received(:delete_tasks)
      end

      it 'returns false' do
        expect(subject.delete).to be(false)
      end
    end

    context 'when the task is finished' do
      before do
        task_hash['status'] = 'failed'
        not_found_error = Meilisearch::ApiError.new(404, '', '')
        allow(endpoint).to receive(:task) { raise not_found_error }
      end

      it 'makes a deletion request' do
        subject.delete
        expect(endpoint).to have_received(:delete_tasks)
      end

      it 'returns true' do
        expect(subject.delete).to be(true)
      end
    end
  end

  describe '#refresh' do
    let(:changed_task) { task_hash.merge('status' => 'succeeded', 'error' => 'Done too well') }
    let(:endpoint) { instance_double(Meilisearch::Task, task: changed_task) }

    it 'calls endpoint to update task' do
      expect { subject.refresh }.to change { subject['status'] }.from('enqueued').to('succeeded')
                                .and(change { subject['error'] }.from(nil).to('Done too well'))
    end
  end

  describe '#await' do
    let(:changed_task) { task_hash.merge('status' => 'succeeded', 'error' => 'Done too well') }
    let(:endpoint) { instance_double(Meilisearch::Task, task: task_hash, wait_for_task: changed_task) }

    context 'when the task is not yet completed' do
      let(:endpoint) { instance_double(Meilisearch::Task, task: task_hash, wait_for_task: changed_task) }

      it 'waits for the task to complete' do
        expect { subject.await }.to change { subject['status'] }.from('enqueued').to('succeeded')
                                .and(change { subject['error'] }.from(nil).to('Done too well'))
      end

      it 'returns itself for method chaining' do
        expect(subject.await).to be(subject)
      end
    end

    context 'when the task is already completed' do
      let(:endpoint) { instance_double(Meilisearch::Task, task: changed_task, wait_for_task: changed_task) }

      it 'does not contact the instance' do
        subject.refresh
        subject.await

        expect(endpoint).to have_received(:task).once
        expect(endpoint).not_to have_received(:wait_for_task)
      end
    end
  end

  describe '#error' do
    let(:error) do
      { 'message' => "Index `#{new_index_uid}` already exists.",
        'code' => 'index_already_exists',
        'type' => 'invalid_request',
        'link' => 'https://docs.meilisearch.com/errors#index_already_exists' }
    end

    before { task_hash.merge!('error' => error, 'status' => 'failed') }

    it 'returns errors' do
      expect(subject.error).to match(error)
    end
  end

  describe '#to_h' do
    it 'returns the underlying task hash' do
      expect(subject.to_h).to be(task_hash)
    end

    it 'is aliased as #to_hash' do
      expect(subject.to_hash).to be(subject.to_h)
    end
  end
end
