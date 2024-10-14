# frozen_string_literal: true

module MeiliSearch
  module MultiSearch
    # Performs search on one or more indexes
    #
    # @param [Hash] federation_options
    #   - `limit`: number of results in the merged list
    #   - `offset`: number of results to skip in the merged list
    def multi_search(data, federation_options = nil)
      body = Utils.transform_attributes(data)

      http_post '/multi-search', queries: body, federation: federation_options
    end
  end
end
