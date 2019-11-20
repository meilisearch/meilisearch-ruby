# frozen_string_literal: true

module MeiliSearch
  class Client
    module Keys
      def keys
        get '/keys'
      end

      def key(key_hash)
        get "/keys/#{key_hash}"
      end

      def create_key(options = {})
        post '/keys', options
      end

      def update_key(key_hash, options = {})
        put "/keys/#{key_hash}", options
      end

      def delete_key(key_hash)
        delete "/keys/#{key_hash}"
      end
    end
  end
end
