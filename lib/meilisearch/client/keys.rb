# frozen_string_literal: true

module MeiliSearch
  class Client < HTTPRequest
    module Keys
      def keys
        http_get '/keys'
      end

      def key(key_hash)
        http_get "/keys/#{key_hash}"
      end

      def create_key(options = {})
        http_post '/keys', options
      end

      def update_key(key_hash, options = {})
        http_put "/keys/#{key_hash}", options
      end

      def delete_key(key_hash)
        http_delete "/keys/#{key_hash}"
      end
    end
  end
end
