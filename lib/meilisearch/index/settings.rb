# frozen_string_literal: true

module MeiliSearch
  class Index < HTTPRequest
    module Settings
      def settings
        http_get "/indexes/#{@uid}/settings"
      end
      alias get_settings settings

      def add_or_replace_settings(options)
        http_post "/indexes/#{@uid}/settings", options
      end
      alias add_settings add_or_replace_settings
      alias replace_settings add_or_replace_settings

      def reset_all_settings
        body = {
          rankingOrder: nil,
          distinctField: nil,
          rankingRules: nil
        }
        http_post "/indexes/#{@uid}/settings", body
      end
    end
  end
end
