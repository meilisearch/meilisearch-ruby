# frozen_string_literal: true

module Meilisearch
  class Index
    # Searches for facet values matching a query.
    # @see https://www.meilisearch.com/docs/reference/api/facet_search Meilisearch API Reference
    module FacetSearch
      # Search for facet values.
      #
      #   client.index('books').facet_search('genres', 'fiction', filter: 'rating > 3')
      #   # {
      #   #   "facetHits": [
      #   #     {
      #   #       "value": "fiction",
      #   #       "count": 7
      #   #     }
      #   #   ],
      #   #   "facetQuery": "fiction",
      #   #   "processingTimeMs": 0
      #   # }
      #
      # @param name [String] Facet name to search values on.
      # @param query [String] Search query for a given facet value.
      # @param options [Hash{Symbol => Object}] Additional options, see API Reference.
      # @return [Hash{String => Object}] Facet search result.
      #
      # @see https://www.meilisearch.com/docs/reference/api/facet_search#perform-a-facet-search Meilisearch API Reference
      def facet_search(name, query = '', **options)
        options.merge!(facet_name: name, facet_query: query)
        options = Utils.transform_attributes(options)

        http_post("/indexes/#{@uid}/facet-search", options)
      end
    end

    include FacetSearch
  end
end
