# frozen_string_literal: true

module MeiliSearch
  class Client < HTTPRequest
    module Keys
      def keys
        http_get '/keys'
      end

      def key(key)
        http_get "/keys/#{key}"
      end

      def create_key(options = {})
        http_post '/keys', options
      end

      def update_key(key, options = {})
        http_put "/keys/#{key}", options
      end

      def delete_key(key)
        http_delete "/keys/#{key}"
      end
    end
  end
end
