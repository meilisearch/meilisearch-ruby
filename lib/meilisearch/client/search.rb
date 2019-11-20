# frozen_string_literal: true

module MeiliSearch
  class Client
    module Search
      def search(index_uid, query, options = {})
        get "/indexes/#{index_uid}/search", { q: query }.merge(options)
      end
    end
  end
end
