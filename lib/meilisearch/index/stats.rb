# frozen_string_literal: true

module Meilisearch
  class Index
    # Provides index statistics such as document count, field distribution, and indexing status.
    # @see https://www.meilisearch.com/docs/reference/api/stats Meilisearch API Reference
    module Stats
      # Get stats of this index.
      #
      # @return [Hash{String => Object}]
      # @see https://www.meilisearch.com/docs/reference/api/stats#get-stats-of-an-index Meilisearch API Reference
      def stats
        http_get "/indexes/#{@uid}/stats"
      end

      # Get the number of documents in the index.
      #
      # Calls {#stats}
      #
      # @return [Integer]
      def number_of_documents
        stats['numberOfDocuments']
      end

      # Get the filed distribution of documents in the index.
      #
      # Calls {#stats}
      def field_distribution
        stats['fieldDistribution']
      end

      # Whether the index is currently in the middle of indexing documents.
      #
      # Calls {#stats}
      # @return [Boolean]
      def indexing?
        stats['isIndexing']
      end
    end

    include Stats
  end
end
