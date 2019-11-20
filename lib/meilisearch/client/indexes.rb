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

      def create_index(index_uid, schema = nil)
        if schema.nil?
          post "/indexes/#{index_uid}"
        else
          post "/indexes/#{index_uid}", schema
        end
      end

      def update_index(index_uid, schema = nil)
        put "/indexes/#{index_uid}", schema
      end

      def delete_index(index_uid)
        delete "/indexes/#{index_uid}"
      end
    end
  end
end
