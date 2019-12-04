# frozen_string_literal: true

module MeiliSearch
  class Index < HTTPRequest
    module Base

      def show
        http_get "/indexes/#{@uid}"
      end
      alias_method :show_index, :show

      def schema
        begin
          http_get "/indexes/#{@uid}/schema"
        rescue HTTPError => e
          raise if e.body_message != 'missing index schema'
          nil
        end
      end
      alias_method :get_schema, :schema

      def update_name(new_index_name)
        http_put "/indexes/#{@uid}", { name: new_index_name }
      end
      alias_method :update_index_name, :update_name

      def update_schema(new_schema)
        http_put "/indexes/#{@uid}/schema", new_schema
      end
      alias_method :update_index_schema, :update_schema

      def delete
        http_delete "/indexes/#{@uid}"
      end
      alias_method :delete_index, :delete

    end
  end
end
