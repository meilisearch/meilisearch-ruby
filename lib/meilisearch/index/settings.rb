# frozen_string_literal: true

module MeiliSearch
  class Index < HTTPRequest
    module Settings
      def settings
        http_get "/indexes/#{@uid}/settings"
      end
      alias_method :get_settings, :settings

      def add_or_update_settings(options = nil)
        http_post "/indexes/#{@uid}/settings", options
      end
      alias_method :add_settings,    :add_or_update_settings
      alias_method :update_settings, :add_or_update_settings
    end
  end
end
