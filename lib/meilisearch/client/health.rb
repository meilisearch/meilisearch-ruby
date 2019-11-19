# frozen_string_literal: true

module MeiliSearch
  class Client
    module Health
      def is_healthy?
        get '/health'
        true
      rescue StandardError
        false
      end

      def health
        get '/health'
      end

      def update_health(bool)
        put '/health', health: bool
      end
    end
  end
end
