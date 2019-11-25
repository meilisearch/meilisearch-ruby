# frozen_string_literal: true

module MeiliSearch
  class Client
    module Indexes
      def indexes
        get '/indexes'
      end

      def index(index_uid)
        get "/indexes/#{index_uid}"
      end

      def create_index(index_name, schema = nil)
        body = { name: index_name, schema: schema }.compact
        post '/indexes', body
      end

      def update_index_name(index_uid, index_name)
        put "/indexes/#{index_uid}", { name: index_name }
      end

      def delete_index(index_uid)
        delete "/indexes/#{index_uid}"
      end

      def get_index_schema(index_uid)
        get "/indexes/#{index_uid}/schema"
      end

      def update_index_schema(index_uid, new_schema)
        put "/indexes/#{index_uid}/schema", new_schema
      end
    end
  end
end
