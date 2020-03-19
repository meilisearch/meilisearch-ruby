# frozen_string_literal: true

module MeiliSearch
  class Client < HTTPRequest
    module Indexes
      def indexes
        http_get '/indexes'
      end

      def show_index(index_uid)
        index_object(index_uid).show
      end

      # Usage:
      # create_index('indexUID')
      # create_index(uid: 'indexUID')
      # create_index(uid: 'indexUID', primaryKey: 'id')
      def create_index(attributes)
        body = if attributes.is_a?(Hash)
                 attributes
               else
                 { uid: attributes }
               end
        res = http_post '/indexes', body
        index_object(res['uid'])
      end

      def delete_index(index_uid)
        index_object(index_uid).delete
      end

      # Usage:
      # index('indexUID')
      # index(uid: 'indexUID')
      def index(attribute)
        uid = attribute.is_a?(Hash) ? attribute[:uid] : attribute
        raise IndexUidError if uid.nil?

        index_object(uid)
      end
      alias get_index index

      private

      def index_object(uid)
        Index.new(uid, @base_url, @api_key)
      end
    end
  end
end
