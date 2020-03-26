# frozen_string_literal: true

module MeiliSearch
  class Client < HTTPRequest
    module Keys
      def keys
        http_get '/keys'
      end
      alias get_keys keys
    end
  end
end
