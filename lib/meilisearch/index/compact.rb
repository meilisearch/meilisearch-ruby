# frozen_string_literal: true

module Meilisearch
  class Index
    # Runs database compaction to optimize disk usage.
    module Compact
      # Run database compaction for this index.
      #
      # @note Meilisearch must temporarily duplicate the database during compaction.
      #   You need at least twice the current size of your database in free disk space.
      #
      # @see https://www.meilisearch.com/docs/reference/api/compact Meilisearch API Reference
      # @return [Models::Task] The index compaction async task.
      def compact
        response = http_post "/indexes/#{@uid}/compact"
        Models::Task.new(response, task_endpoint)
      end
    end

    include Compact
  end
end
