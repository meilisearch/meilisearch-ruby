# frozen_string_literal: true

module MeiliSearch
  class Index < HTTPRequest
    module Settings
      # General routes
      def settings
        http_get "/indexes/#{@uid}/settings"
      end
      alias get_settings settings

      def update_settings(settings)
        http_post "/indexes/#{@uid}/settings", settings
      end

      def reset_settings
        http_delete "/indexes/#{@uid}/settings"
      end

      # Sub-routes ranking rules
      def ranking_rules
        http_get "/indexes/#{@uid}/settings/ranking-rules"
      end
      alias get_ranking_rules ranking_rules

      def update_ranking_rules(ranking_rules)
        http_post "/indexes/#{@uid}/settings/ranking-rules", ranking_rules
      end

      def reset_ranking_rules
        http_delete "/indexes/#{@uid}/settings/ranking-rules"
      end

      # Sub-routes distinct attribute
      def distinct_attribute
        http_get "/indexes/#{@uid}/settings/distinct-attribute"
      end
      alias get_distinct_attribute distinct_attribute

      def update_distinct_attribute(distinct_attribute)
        http_post "/indexes/#{@uid}/settings/distinct-attribute", distinct_attribute
      end

      def reset_distinct_attribute
        http_delete "/indexes/#{@uid}/settings/distinct-attribute"
      end

      # Sub-routes searchable attributes
      def searchable_attributes
        http_get "/indexes/#{@uid}/settings/searchable-attributes"
      end
      alias get_searchable_attributes searchable_attributes

      def update_searchable_attributes(searchable_attributes)
        http_post "/indexes/#{@uid}/settings/searchable-attributes", searchable_attributes
      end

      def reset_searchable_attributes
        http_delete "/indexes/#{@uid}/settings/searchable-attributes"
      end

      # Sub-routes displayed attributes
      def displayed_attributes
        http_get "/indexes/#{@uid}/settings/displayed-attributes"
      end
      alias get_displayed_attributes displayed_attributes

      def update_displayed_attributes(displayed_attributes)
        http_post "/indexes/#{@uid}/settings/displayed-attributes", displayed_attributes
      end

      def reset_displayed_attributes
        http_delete "/indexes/#{@uid}/settings/displayed-attributes"
      end

      # Sub-routes accept-new-fields
      def accept_new_fields
        http_get "/indexes/#{@uid}/settings/accept-new-fields"
      end
      alias get_accept_new_fields accept_new_fields

      def update_accept_new_fields(accept_new_fields)
        http_post "/indexes/#{@uid}/settings/accept-new-fields", accept_new_fields
      end
    end
  end
end
