# frozen_string_literal: true

module Meilisearch
  module MultiSearch
    # Performs search on one or more indexes
    #
    # @param [Hash] federation_options
    #   - `limit`: number of results in the merged list
    #   - `offset`: number of results to skip in the merged list
    def multi_search(data = nil, queries: [], federation: nil)
      Utils.soft_deprecate('multi_search([])', 'multi_search(queries: [])') if data

      queries += data if data

      queries = Utils.transform_attributes(queries)
      federation = Utils.transform_attributes(federation)

      http_post '/multi-search', queries: queries, federation: federation
    end
  end
end
