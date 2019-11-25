# frozen_string_literal: true

module MeiliSearch
  class Index < HTTPRequest
    module Search
      def search(query, options = {})
        http_get "/indexes/#{@uid}/search", { q: query }.merge(options)
      end
    end
  end
end
