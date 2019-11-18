module MeiliSearch
  class Client
    module Health

      def health?
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
