module MeiliSearch
  class Client
    module Indexes
      def indexes
        get '/indexes'
      end

      def index(index_uid)
        get "/indexes/#{index_uid}"
      end

      def create_index(schema_name, schema)
        post "/indexes/#{schema_name}", schema
      end

      def clear_index(index_uid)
        post "/indexes/#{index_uid}/documents/clear"
      end

      def delete_index(index_uid)
        delete "/indexes/#{index_uid}"
      end
    end
  end
end
