# frozen_string_literal: true

module Meilisearch
  class Index
    # Performs keyword and similarity-based search queries on an index.
    # @see https://www.meilisearch.com/docs/reference/api/search Meilisearch API Reference
    module Search
      # Run a search on this index.
      #
      # Check Meilisearch API Reference for all options.
      #
      # @param query [String] The query string for the search.
      # @param options [Hash{Symbol => Object}] Search options.
      #
      # @return [Hash{String => Object}] Search results
      # @see https://www.meilisearch.com/docs/reference/api/search#search-in-an-index-with-post Meilisearch API Reference
      def search(query, options = {})
        attributes = { q: query.to_s }.merge(options.compact)

        parsed_options = Utils.transform_attributes(attributes)
        response = http_post "/indexes/#{@uid}/search", parsed_options

        response['nbHits'] ||= response['estimatedTotalHits'] unless response.key?('totalPages')

        response
      end

      # Run a search for semantically similar documents.
      #
      # An embedder must be configured and specified.
      # Check Meilisearch API Reference for all options.
      #
      # @param document_id [String, Integer] The base document for comparisons.
      # @param options [Hash{Symbol => Object}] Search options. Including a mandatory :embedder option.
      #
      # @return [Hash{String => Object}] Search results
      # @see https://www.meilisearch.com/docs/reference/api/similar#get-similar-documents-with-post Meilisearch API Reference
      def search_similar_documents(document_id, **options)
        options.merge!(id: document_id)
        options = Utils.transform_attributes(options)

        http_post("/indexes/#{@uid}/similar", options)
      end
    end

    include Search
  end
end
