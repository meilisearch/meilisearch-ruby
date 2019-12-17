# frozen_string_literal: true

module MeiliSearch
  class Index < HTTPRequest
    module Updates
      def get_update_status(update_id)
        http_get "/indexes/#{@uid}/updates/#{update_id}"
      end

      def get_all_update_status
        http_get "/indexes/#{@uid}/updates"
      end
    end
  end
end
