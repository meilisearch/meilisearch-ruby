# frozen_string_literal: true

require 'forwardable'

module MeiliSearch
  module Models
    class Task
      extend Forwardable

      # Maintain backwards compatibility with task hash return type
      def_delegators :metadata, :[], :dig, :keys, :key?, :has_key?

      attr_reader :metadata

      def initialize(metadata_hash, task_endpoint)
        self.metadata = metadata_hash
        validate_required_fields! metadata

        @task_endpoint = task_endpoint
      end

      def uid
        @metadata['taskUid']
      end

      def type
        @metadata['type']
      end

      def status
        @metadata['status']
      end

      def enqueued?
        refresh if status_enqueued?

        status_enqueued?
      end

      def processing?
        refresh if status_processing? || status_enqueued?

        status_processing?
      end

      def unfinished?
        refresh if status_processing? || status_enqueued?

        status_processing? || status_enqueued?
      end
      alias waiting? unfinished?

      def finished?
        !unfinished?
      end

      def succeeded?
        Utils.warn_on_unfinished_task(self) if unfinished?

        status == 'succeeded'
      end
      alias has_succeeded? succeeded?

      def failed?
        Utils.warn_on_unfinished_task(self) if unfinished?

        status == 'failed'
      end
      alias has_failed? failed?

      def cancelled?
        Utils.warn_on_unfinished_task(self) if unfinished?

        status_cancelled?
      end

      def deleted?
        refresh unless @deleted

        !!@deleted
      end

      def error
        @metadata['error']
      end

      def refresh(with: nil)
        self.metadata = with || @task_endpoint.task(uid)

        self
      rescue MeiliSearch::ApiError => e
        raise e unless e.http_code == 404

        @deleted = true

        self
      end

      def await(timeout_in_ms = 5000, interval_in_ms = 50)
        refresh with: @task_endpoint.wait_for_task(uid, timeout_in_ms, interval_in_ms) unless finished?

        self
      end

      def cancel
        return true if status_cancelled?
        return false if status_finished?

        @task_endpoint.cancel_tasks(uids: [uid]).await

        cancelled?
      end

      def delete
        return false unless status_finished?

        @task_endpoint.delete_tasks(uids: [uid]).await

        deleted?
      end

      def to_h
        @metadata
      end
      alias to_hash to_h

      private

      def validate_required_fields!(task_hash)
        raise ArgumentError, 'Cannot instantiate a task without an ID'    unless task_hash['taskUid']
        raise ArgumentError, 'Cannot instantiate a task without a type'   unless task_hash['type']
        raise ArgumentError, 'Cannot instantiate a task without a status' unless task_hash['status']
      end

      def status_enqueued?
        status == 'enqueued'
      end

      def status_processing?
        status == 'processing'
      end

      def status_finished?
        ['succeeded', 'failed', 'cancelled'].include? status
      end

      def status_cancelled?
        status == 'cancelled'
      end

      def metadata=(metadata)
        @metadata = metadata

        uid = @metadata['taskUid'] || @metadata['uid']
        @metadata['uid'] = uid
        @metadata['taskUid'] = uid
      end
    end
  end
end
