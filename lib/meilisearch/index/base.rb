# frozen_string_literal: true

module MeiliSearch
  class Index < HTTPRequest
    module Base
      def show
        http_get "/indexes/#{@uid}"
      end
      alias show_index show

      def update(body)
        http_put "/indexes/#{@uid}", body
      end
      alias update_index update

      def delete
        http_delete "/indexes/#{@uid}"
      end
      alias delete_index delete
    end
  end
end
