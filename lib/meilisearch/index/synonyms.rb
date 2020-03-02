# frozen_string_literal: true

module MeiliSearch
  class Index < HTTPRequest
    module Synonyms
      def synonyms
        http_get "/indexes/#{@uid}/settings/synonyms"
      end
      alias get_synonyms synonyms

      def update_synonyms(synonyms)
        http_post "/indexes/#{@uid}/settings/synonyms", synonyms
      end

      def reset_synonyms
        http_delete "/indexes/#{@uid}/settings/synonyms"
      end
    end
  end
end
