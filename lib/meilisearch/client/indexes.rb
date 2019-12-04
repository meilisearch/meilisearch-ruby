# frozen_string_literal: true

module MeiliSearch
  class Client < HTTPRequest
    module Indexes
      def indexes
        http_get '/indexes'
      end

      def show_index(index_uid)
        http_get "/indexes/#{index_uid}"
      end

      def create_index(index_name, schema = nil)
        body = { name: index_name, schema: schema }.compact
        res = http_post '/indexes', body
        index_object(res['uid'])
      end

      def delete_index(index_uid)
        Index.new(index_uid, @base_url, @api_key).delete
      end

      # Usage:
      # index('uid')
      # index(uid: 'uid')
      # index(name: 'name') => WARNING: the name of an index is not guaranteed to be unique. This method will return the first occurrence. We recommend using the index uid instead.
      # index(uid: 'uid', name: 'name') => only the uid field will be taken into account.
      def index(identifier)
        uid = get_index_uid(identifier)
        raise IndexIdentifierError if uid.nil?
        index_object(uid)
      end
      alias_method :get_index, :index

      private

      def index_object(uid)
        Index.new(uid, @base_url, @api_key)
      end

      def get_index_uid(identifier)
        if identifier.is_a?(Hash)
          identifier[:uid] || get_index_uid_from_name(identifier)
        else
          identifier
        end
      end

      def get_index_uid_from_name(identifier)
        index = indexes.find { |index| index['name'] == identifier[:name] }
        if index.nil?
          nil
        else
          index['uid']
        end
      end

    end
  end
end
