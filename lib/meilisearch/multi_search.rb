# frozen_string_literal: true

module MeiliSearch
  module MultiSearch
    def multi_search(data)
      body = Utils.transform_attributes(data)

      http_post '/multi-search', queries: body
    end
  end
end
