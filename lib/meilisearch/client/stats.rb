# frozen_string_literal: true

module MeiliSearch
  class Client < HTTPRequest
    module Stats
      def version
        http_get '/version'
      end

      def sysinfo
        http_get '/sys-info'
      end

      def pretty_sysinfo
        http_get '/sys-info/pretty'
      end

      def stats
        http_get '/stats'
      end
    end
  end
end
