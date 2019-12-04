# frozen_string_literal: true

module MeiliSearch
  class Client < HTTPRequest
    module Health
      def is_healthy?
        http_get '/health'
        true
      rescue StandardError
        false
      end

      def health
        http_get '/health'
      end

      def update_health(bool)
        http_put '/health', health: bool
      end
    end
  end
end
