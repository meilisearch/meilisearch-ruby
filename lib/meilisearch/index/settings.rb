# frozen_string_literal: true

module Meilisearch
  class Index
    # Manages index settings such as ranking rules, filterable attributes, stop words, and more.
    # @see https://www.meilisearch.com/docs/reference/api/settings Meilisearch API Reference
    module Settings
      ### SETTINGS - GENERAL

      # Get all index settings.
      #
      # @return [Hash{String => Object}] See the {settings object}[https://www.meilisearch.com/docs/reference/api/settings#settings-object].
      # @see https://www.meilisearch.com/docs/reference/api/settings#all-settings Meilisearch API Reference
      def settings
        http_get "/indexes/#{@uid}/settings"
      end
      alias get_settings settings

      # Update index settings.
      #
      # @param settings [Hash{Symbol => Object}] The new settings.
      #   Settings missing from this parameter are not affected.
      #   See {all settings}[https://www.meilisearch.com/docs/reference/api/settings#body].
      #
      # @return [Models::Task] The setting update async task.
      # @see https://www.meilisearch.com/docs/reference/api/settings#update-settings Meilisearch API Reference
      def update_settings(settings)
        response = http_patch "/indexes/#{@uid}/settings", Utils.transform_attributes(settings)
        Models::Task.new(response, task_endpoint)
      end
      alias settings= update_settings

      # Reset all index settings to defaults.
      #
      # @return [Models::Task] The setting update async task.
      # @see https://www.meilisearch.com/docs/reference/api/settings#reset-settings Meilisearch API Reference
      def reset_settings
        response = http_delete "/indexes/#{@uid}/settings"
        Models::Task.new(response, task_endpoint)
      end

      ### SETTINGS - RANKING RULES

      # Get the index's ranking rules.
      #
      # Ranking rules are built-in rules that rank search results according to certain criteria.
      # They are applied in the same order in which they appear in the rankingRules array.
      #
      # @return [Array<String>]
      # @see https://www.meilisearch.com/docs/reference/api/settings#ranking-rules  Meilisearch API Reference
      def ranking_rules
        http_get "/indexes/#{@uid}/settings/ranking-rules"
      end
      alias get_ranking_rules ranking_rules

      # Update ranking rules.
      #
      #   client.index('movies').update_ranking_rules([
      #     'words',
      #     'typo',
      #     'proximity',
      #     'attribute',
      #     'sort',
      #     'exactness',
      #     'release_date:asc',
      #     'rank:desc'
      #   ])
      #
      # See {#ranking_rules} for more details.
      #
      # @return [Models::Task] The async update task.
      def update_ranking_rules(ranking_rules)
        response = http_put "/indexes/#{@uid}/settings/ranking-rules", ranking_rules
        Models::Task.new(response, task_endpoint)
      end
      alias ranking_rules= update_ranking_rules

      # Reset ranking rules to defaults.
      #
      # See {#ranking_rules} for more details.
      #
      # @return [Models::Task] The async update task that does the reset.
      def reset_ranking_rules
        response = http_delete "/indexes/#{@uid}/settings/ranking-rules"
        Models::Task.new(response, task_endpoint)
      end

      ### SETTINGS - SYNONYMS

      # Get the index's synonyms object.
      #
      # The synonyms object contains words and their respective synonyms.
      # A synonym in Meilisearch is considered equal to its associated word for the purposes of calculating search results.
      #
      # @return [Hash{String => Array<String>}]
      # @see https://www.meilisearch.com/docs/reference/api/settings#synonyms  Meilisearch API Reference
      def synonyms
        http_get "/indexes/#{@uid}/settings/synonyms"
      end
      alias get_synonyms synonyms

      # Set the synonyms setting.
      #
      # @param synonyms [Array<String>]
      # @return [Models::Task] The async update task.
      # @see #synonyms
      def update_synonyms(synonyms)
        response = http_put "/indexes/#{@uid}/settings/synonyms", synonyms
        Models::Task.new(response, task_endpoint)
      end
      alias synonyms= update_synonyms

      # Reset synonyms setting to its default.
      #
      # @see #synonyms
      # @return [Models::Task] The async update task that does the reset.
      def reset_synonyms
        response = http_delete "/indexes/#{@uid}/settings/synonyms"
        Models::Task.new(response, task_endpoint)
      end

      ### SETTINGS - STOP-WORDS

      # Get the index's stop-words list.
      #
      # Words added to the stopWords list are ignored in future search queries.
      #
      # @return [Array<String>]
      # @see https://www.meilisearch.com/docs/reference/api/settings#stop-words  Meilisearch API Reference
      def stop_words
        http_get "/indexes/#{@uid}/settings/stop-words"
      end
      alias get_stop_words stop_words

      # Set the stop-words setting.
      #
      # @param stop_words [Array<String>]
      # @return [Models::Task] The async update task.
      # @see #stop_words
      def update_stop_words(stop_words)
        body = stop_words.nil? || stop_words.is_a?(Array) ? stop_words : [stop_words]
        response = http_put "/indexes/#{@uid}/settings/stop-words", body
        Models::Task.new(response, task_endpoint)
      end
      alias stop_words= update_stop_words

      # Reset stop-words setting to its default.
      #
      # @see #stop_words
      # @return [Models::Task] The async update task that does the reset.
      def reset_stop_words
        response = http_delete "/indexes/#{@uid}/settings/stop-words"
        Models::Task.new(response, task_endpoint)
      end

      ### SETTINGS - DISTINCT ATTRIBUTE

      # Get the index's distinct attribute.
      #
      # The distinct attribute is a field whose value will always be unique in the returned documents.
      #
      # @return [String]
      # @see https://www.meilisearch.com/docs/reference/api/settings#distinct-attribute  Meilisearch API Reference
      def distinct_attribute
        http_get "/indexes/#{@uid}/settings/distinct-attribute"
      end
      alias get_distinct_attribute distinct_attribute

      # Set the distinct-attribute setting.
      #
      # @param distinct_attribute [String]
      # @return [Models::Task] The async update task.
      # @see #distinct_attribute
      def update_distinct_attribute(distinct_attribute)
        response = http_put "/indexes/#{@uid}/settings/distinct-attribute", distinct_attribute
        Models::Task.new(response, task_endpoint)
      end
      alias distinct_attribute= update_distinct_attribute

      # Reset distinct attribute setting to its default.
      #
      # @see #distinct_attribute
      # @return [Models::Task] The async update task that does the reset.
      def reset_distinct_attribute
        response = http_delete "/indexes/#{@uid}/settings/distinct-attribute"
        Models::Task.new(response, task_endpoint)
      end

      ### SETTINGS - SEARCHABLE ATTRIBUTES

      # Get the index's searchable attributes.
      #
      # The values associated with attributes in the searchable_attributes list are searched for matching query words.
      # The order of the list also determines the attribute ranking order.
      # Defaults to +["*"]+.
      #
      # @return [Array<String>]
      # @see https://www.meilisearch.com/docs/reference/api/settings#searchable-attributes  Meilisearch API Reference
      def searchable_attributes
        http_get "/indexes/#{@uid}/settings/searchable-attributes"
      end
      alias get_searchable_attributes searchable_attributes

      # Set the searchable attributes.
      #
      # @param distinct_attribute [Array<String>]
      # @return [Models::Task] The async update task.
      # @see #searchable_attributes
      def update_searchable_attributes(searchable_attributes)
        response = http_put "/indexes/#{@uid}/settings/searchable-attributes", searchable_attributes
        Models::Task.new(response, task_endpoint)
      end
      alias searchable_attributes= update_searchable_attributes

      # Reset searchable attributes setting to its default.
      #
      # @see #searchable_attributes
      # @return [Models::Task] The async update task that does the reset.
      def reset_searchable_attributes
        response = http_delete "/indexes/#{@uid}/settings/searchable-attributes"
        Models::Task.new(response, task_endpoint)
      end

      ### SETTINGS - DISPLAYED ATTRIBUTES

      # Get the index's displayed attributes.
      #
      # The attributes added to the displayedAttributes list appear in search results.
      # Only affects the search endpoints.
      #
      # @return [Array<String>]
      # @see https://www.meilisearch.com/docs/reference/api/settings#displayed-attributes  Meilisearch API Reference
      def displayed_attributes
        http_get "/indexes/#{@uid}/settings/displayed-attributes"
      end
      alias get_displayed_attributes displayed_attributes

      # Set the displayed attributes.
      #
      # @param displayed_attributes [Array<String>]
      # @return [Models::Task] The async update task.
      # @see #displayed_attributes
      def update_displayed_attributes(displayed_attributes)
        response = http_put "/indexes/#{@uid}/settings/displayed-attributes", displayed_attributes
        Models::Task.new(response, task_endpoint)
      end
      alias displayed_attributes= update_displayed_attributes

      # Reset displayed attributes setting to its default.
      #
      # @see #displayed_attributes
      # @return [Models::Task] The async update task that does the reset.
      def reset_displayed_attributes
        response = http_delete "/indexes/#{@uid}/settings/displayed-attributes"
        Models::Task.new(response, task_endpoint)
      end

      ### SETTINGS - FILTERABLE ATTRIBUTES

      # Get the index's filterable attributes.
      #
      # Attributes in the filterable_attributes list can be used as filters or facets.
      #
      # @return [Array<String>]
      # @see https://www.meilisearch.com/docs/reference/api/settings#filterable-attributes  Meilisearch API Reference
      def filterable_attributes
        http_get "/indexes/#{@uid}/settings/filterable-attributes"
      end
      alias get_filterable_attributes filterable_attributes

      # Set the filterable attributes.
      #
      # @param filterable_attributes [Array<String>]
      # @return [Models::Task] The async update task.
      # @see #filterable_attributes
      def update_filterable_attributes(filterable_attributes)
        response = http_put "/indexes/#{@uid}/settings/filterable-attributes", filterable_attributes
        Models::Task.new(response, task_endpoint)
      end
      alias filterable_attributes= update_filterable_attributes

      # Reset filterable attributes setting to its default.
      #
      # @see #filterable_attributes
      # @return [Models::Task] The async update task that does the reset.
      def reset_filterable_attributes
        response = http_delete "/indexes/#{@uid}/settings/filterable-attributes"
        Models::Task.new(response, task_endpoint)
      end

      ### SETTINGS - SORTABLE ATTRIBUTES

      # Get the index's sortable attributes.
      #
      # Attributes that can be used when sorting search results using the sort search parameter.
      #
      # @return [Array<String>]
      # @see https://www.meilisearch.com/docs/reference/api/settings#stop-words  Meilisearch API Reference
      # @see https://www.meilisearch.com/docs/reference/api/search#sort +sort+ search parameter
      def sortable_attributes
        http_get "/indexes/#{@uid}/settings/sortable-attributes"
      end
      alias get_sortable_attributes sortable_attributes

      # Set the sortable attributes.
      #
      # @param sortable_attributes [Array<String>]
      # @return [Models::Task] The async update task.
      # @see #sortable_attributes
      def update_sortable_attributes(sortable_attributes)
        response = http_put "/indexes/#{@uid}/settings/sortable-attributes", sortable_attributes
        Models::Task.new(response, task_endpoint)
      end
      alias sortable_attributes= update_sortable_attributes

      # Reset sortable attributes setting to its default.
      #
      # @see #sortable_attributes
      # @return [Models::Task] The async update task that does the reset.
      def reset_sortable_attributes
        response = http_delete "/indexes/#{@uid}/settings/sortable-attributes"
        Models::Task.new(response, task_endpoint)
      end

      ### SETTINGS - PAGINATION

      # Get the index's pagination options.
      #
      # To protect your database from malicious scraping, Meilisearch has a default limit of 1000 results per search.
      # This setting allows you to configure the maximum number of results returned per search.
      #
      # @return [Hash{String => Integer}]
      # @see https://www.meilisearch.com/docs/reference/api/settings#pagination  Meilisearch API Reference
      def pagination
        http_get("/indexes/#{@uid}/settings/pagination")
      end
      alias get_pagination pagination

      # Set the pagination options.
      #
      # @param sortable_attributes [Hash{String => Integer}]
      # @return [Models::Task] The async update task.
      # @see #pagination
      def update_pagination(pagination)
        response = http_patch "/indexes/#{@uid}/settings/pagination", pagination
        Models::Task.new(response, task_endpoint)
      end
      alias pagination= update_sortable_attributes

      # Reset pagination setting to its default.
      #
      # @see #pagination
      # @return [Models::Task] The async update task that does the reset.
      def reset_pagination
        response = http_delete "/indexes/#{@uid}/settings/pagination"
        Models::Task.new(response, task_endpoint)
      end

      ### SETTINGS - TYPO TOLERANCE

      # Get the index's typo tolerance setting.
      #
      # This setting allows you to configure the minimum word size for typos and disable typo tolerance for specific words or attributes.
      #
      # @return [Hash{String => Object}]
      # @see https://www.meilisearch.com/docs/reference/api/settings#typo-tolerance Meilisearch API Reference
      def typo_tolerance
        http_get("/indexes/#{@uid}/settings/typo-tolerance")
      end
      alias get_typo_tolerance typo_tolerance

      # Set the typo tolerance setting.
      #
      # @param sortable_attributes [Hash{String => Object}]
      # @return [Models::Task] The async update task.
      # @see #typo_tolerance
      def update_typo_tolerance(typo_tolerance_attributes)
        attributes = Utils.transform_attributes(typo_tolerance_attributes)
        response = http_patch("/indexes/#{@uid}/settings/typo-tolerance", attributes)
        Models::Task.new(response, task_endpoint)
      end
      alias typo_tolerance= update_typo_tolerance

      # Reset typo tolerance setting to its default.
      #
      # @see #typo_tolerance
      # @return [Models::Task] The async update task that does the reset.
      # Reset typo tolerance setting to its default.
      #
      # @see #typo_tolerance
      # @return [Models::Task] The async update task that does the reset.
      def reset_typo_tolerance
        response = http_delete("/indexes/#{@uid}/settings/typo-tolerance")
        Models::Task.new(response, task_endpoint)
      end

      ### SETTINGS - FACETING

      # Get the index's faceting settings.
      #
      # With Meilisearch, you can create faceted search interfaces. This setting allows you to:
      # * Define the maximum number of values returned by the facets search parameter
      # * Sort facet values by value count or alphanumeric order
      #
      #
      # @return [Hash{String => Object}]
      # @see https://www.meilisearch.com/docs/reference/api/settings#faceting  Meilisearch API Reference
      def faceting
        http_get("/indexes/#{@uid}/settings/faceting")
      end
      alias get_faceting faceting

      # Set the faceting setting.
      #
      # @param faceting_attributes [Hash{String => Object}]
      # @return [Models::Task] The async update task.
      # @see #faceting
      def update_faceting(faceting_attributes)
        attributes = Utils.transform_attributes(faceting_attributes)
        response = http_patch("/indexes/#{@uid}/settings/faceting", attributes)
        Models::Task.new(response, task_endpoint)
      end
      alias faceting= update_faceting

      # Reset faceting setting to its default.
      #
      # @see #faceting
      # @return [Models::Task] The async update task that does the reset.
      def reset_faceting
        response = http_delete("/indexes/#{@uid}/settings/faceting")
        Models::Task.new(response, task_endpoint)
      end

      ### SETTINGS - DICTIONARY

      # Get the index's dictionary.
      #
      # Allows users to instruct Meilisearch to consider groups of strings as a single term by adding a supplementary dictionary of user-defined terms.
      #
      # @return [Array<String>]
      # @see https://www.meilisearch.com/docs/reference/api/settings#dictionary  Meilisearch API Reference
      def dictionary
        http_get("/indexes/#{@uid}/settings/dictionary")
      end

      # Set the custom dictionary.
      #
      # @param dictionary_attributes [Array<String>]
      # @return [Models::Task] The async update task.
      # @see #dictionary
      def update_dictionary(dictionary_attributes)
        attributes = Utils.transform_attributes(dictionary_attributes)
        response = http_put("/indexes/#{@uid}/settings/dictionary", attributes)
        Models::Task.new(response, task_endpoint)
      end

      # Reset dictionary setting to its default.
      #
      # @see #dictionary
      # @return [Models::Task] The async update task that does the reset.
      def reset_dictionary
        response = http_delete("/indexes/#{@uid}/settings/dictionary")
        Models::Task.new(response, task_endpoint)
      end
      ### SETTINGS - SEPARATOR TOKENS

      # Get the index's separator-tokens list.
      #
      # Strings in the separator-tokens list indicate where a word ends and begins.
      #
      # @return [Array<String>]
      # @see #non_separator_tokens
      # @see https://www.meilisearch.com/docs/learn/engine/datatypes#string List of built-in separator tokens
      # @see https://www.meilisearch.com/docs/reference/api/settings#separator-tokens  Meilisearch API Reference
      def separator_tokens
        http_get("/indexes/#{@uid}/settings/separator-tokens")
      end

      # Set the custom separator tokens.
      #
      # @param separator_tokens_attributes [Array<String>]
      # @return [Models::Task] The async update task.
      # @see #separator_tokens
      def update_separator_tokens(separator_tokens_attributes)
        attributes = Utils.transform_attributes(separator_tokens_attributes)
        response = http_put("/indexes/#{@uid}/settings/separator-tokens", attributes)
        Models::Task.new(response, task_endpoint)
      end

      # Reset separator tokens setting to its default.
      #
      # @see #separator_tokens
      # @return [Models::Task] The async update task that does the reset.
      def reset_separator_tokens
        response = http_delete("/indexes/#{@uid}/settings/separator-tokens")
        Models::Task.new(response, task_endpoint)
      end

      ### SETTINGS - NON SEPARATOR TOKENS

      # Get the index's non-separator-token list.
      #
      # Remove words from Meilisearch's default list of separator tokens.
      #
      # @return [Array<String>]
      # @see https://www.meilisearch.com/docs/learn/engine/datatypes#string List of built-in separator tokens
      # @see https://www.meilisearch.com/docs/reference/api/settings#non-separator-tokens  Meilisearch API Reference
      def non_separator_tokens
        http_get("/indexes/#{@uid}/settings/non-separator-tokens")
      end

      # Set the custom non separator tokens.
      #
      # @param non_separator_tokens_attributes [Array<String>]
      # @return [Models::Task] The async update task.
      # @see #non_separator_tokens
      def update_non_separator_tokens(non_separator_tokens_attributes)
        attributes = Utils.transform_attributes(non_separator_tokens_attributes)
        response = http_put("/indexes/#{@uid}/settings/non-separator-tokens", attributes)
        Models::Task.new(response, task_endpoint)
      end

      # Reset non separator tokens setting to its default.
      #
      # @see #non_separator_tokens
      # @return [Models::Task] The async update task that does the reset.
      def reset_non_separator_tokens
        response = http_delete("/indexes/#{@uid}/settings/non-separator-tokens")
        Models::Task.new(response, task_endpoint)
      end

      ### SETTINGS - PROXIMITY PRECISION

      # Get the index's proximity-precision setting.
      #
      # Choose the precision of the distance calculation.
      #
      # @return ["byWord", "byAttribute"]
      # @see https://www.meilisearch.com/docs/reference/api/settings#proximity-precision  Meilisearch API Reference
      def proximity_precision
        http_get("/indexes/#{@uid}/settings/proximity-precision")
      end

      # Set the proximity precision.
      #
      # @param proximity_precision_attribute ["byWord", "byAttribute"]
      # @return [Models::Task] The async update task.
      # @see #proximity_precision
      def update_proximity_precision(proximity_precision_attribute)
        response = http_put("/indexes/#{@uid}/settings/proximity-precision", proximity_precision_attribute)

        Models::Task.new(response, task_endpoint)
      end

      # Reset proximity precision setting to its default.
      #
      # @see #proximity_precision
      # @return [Models::Task] The async update task that does the reset.
      def reset_proximity_precision
        response = http_delete("/indexes/#{@uid}/settings/proximity-precision")

        Models::Task.new(response, task_endpoint)
      end

      ### SETTINGS - SEARCH CUTOFF MS

      # Get the index's maximum duration for a search query, in milliseconds.
      #
      # Defaults to 1500ms.
      #
      # @return [Integer]
      # @see https://www.meilisearch.com/docs/reference/api/settings#search-cuttoff Meilisearch API Reference
      def search_cutoff_ms
        http_get("/indexes/#{@uid}/settings/search-cutoff-ms")
      end

      # Set the search timeout value (in milliseconds).
      #
      # @param search_cutoff_ms_attribute [Integer]
      # @return [Models::Task] The async update task.
      # @see #search_cutoff_ms
      def update_search_cutoff_ms(search_cutoff_ms_attribute)
        response = http_put("/indexes/#{@uid}/settings/search-cutoff-ms", search_cutoff_ms_attribute)

        Models::Task.new(response, task_endpoint)
      end

      # Reset search cutoff ms setting to its default.
      #
      # @see #search_cutoff_ms
      # @return [Models::Task] The async update task that does the reset.
      def reset_search_cutoff_ms
        response = http_delete("/indexes/#{@uid}/settings/search-cutoff-ms")

        Models::Task.new(response, task_endpoint)
      end

      ### SETTINGS - LOCALIZED ATTRIBUTES

      # Get the index's localized-attributes.
      #
      # By default, Meilisearch auto-detects the languages used in your documents.
      # This setting allows you to explicitly define which languages are present in a dataset, and in which fields.
      #
      # @return [Hash{String => Array<String>}]
      # @see https://www.meilisearch.com/docs/reference/api/settings#localized-attributes Meilisearch API Reference
      def localized_attributes
        http_get("/indexes/#{@uid}/settings/localized-attributes")
      end

      # Set the search timeout value (in milliseconds).
      #
      # @param search_cutoff_ms_attribute [Integer]
      # @return [Models::Task] The async update task.
      # @see #search_cutoff_ms
      def update_localized_attributes(new_localized_attributes)
        new_localized_attributes = Utils.transform_attributes(new_localized_attributes)

        response = http_put("/indexes/#{@uid}/settings/localized-attributes", new_localized_attributes)

        Models::Task.new(response, task_endpoint)
      end

      # Reset localized attributes setting to its default.
      #
      # @see #localized_attributes
      # @return [Models::Task] The async update task that does the reset.
      def reset_localized_attributes
        response = http_delete("/indexes/#{@uid}/settings/localized-attributes")

        Models::Task.new(response, task_endpoint)
      end

      ### SETTINGS - FACET SEARCH

      # Get the index's facet-search setting.
      #
      # Processing filterable attributes for facet search is a resource-intensive operation.
      # This feature is enabled by default, but disabling it may speed up indexing.
      #
      # @return [Boolean]
      # @see https://www.meilisearch.com/docs/reference/api/settings#facet-search Meilisearch API Reference
      def facet_search_setting
        http_get("/indexes/#{@uid}/settings/facet-search")
      end

      # Set the facet search setting.
      #
      # @param new_facet_search_setting [Boolean]
      # @return [Models::Task] The async update task.
      # @see #facet_search_setting
      def update_facet_search_setting(new_facet_search_setting)
        response = http_put("/indexes/#{@uid}/settings/facet-search", new_facet_search_setting)

        Models::Task.new(response, task_endpoint)
      end

      # Reset facet search setting setting to its default.
      #
      # @see #facet_search_setting
      # @return [Models::Task] The async update task that does the reset.
      def reset_facet_search_setting
        response = http_delete("/indexes/#{@uid}/settings/facet-search")

        Models::Task.new(response, task_endpoint)
      end

      ### SETTINGS - PREFIX SEARCH

      # Get the index's prefix-search setting.
      #
      # Prefix search is the process through which Meilisearch matches documents that begin with a specific query term, instead of only exact matches.
      # This is a resource-intensive operation that happens during indexing by default.
      #
      # @return ["indexingTime", "disabled"]
      # @see https://www.meilisearch.com/docs/reference/api/settings#prefix-search  Meilisearch API Reference
      def prefix_search
        http_get("/indexes/#{@uid}/settings/prefix-search")
      end

      # Set the prefix search switch.
      #
      # @param new_prefix_search_setting ["indexingTime", "disabled"]
      # @return [Models::Task] The async update task.
      # @see #prefix_search
      def update_prefix_search(new_prefix_search_setting)
        response = http_put("/indexes/#{@uid}/settings/prefix-search", new_prefix_search_setting)

        Models::Task.new(response, task_endpoint)
      end

      # Reset prefix search setting to its default.
      #
      # @see #prefix_search
      # @return [Models::Task] The async update task that does the reset.
      def reset_prefix_search
        response = http_delete("/indexes/#{@uid}/settings/prefix-search")

        Models::Task.new(response, task_endpoint)
      end

      ### SETTINGS - EMBEDDERS

      # Get the index's embedders setting.
      #
      # Embedders translate documents and queries into vector embeddings.
      # You must configure at least one embedder to use AI-powered search.
      #
      # @return [Hash{String => Hash{String => String}}]
      # @see https://www.meilisearch.com/docs/reference/api/settings#embedders  Meilisearch API Reference
      def embedders
        http_get("/indexes/#{@uid}/settings/embedders")
      end

      # Set the embedders on the index.
      #
      # @param new_embedders [Hash{String => Hash{String => String}}]
      # @return [Models::Task] The async update task.
      # @see #embedders
      def update_embedders(new_embedders)
        new_embedders = Utils.transform_attributes(new_embedders)

        response = http_patch("/indexes/#{@uid}/settings/embedders", new_embedders)

        Models::Task.new(response, task_endpoint)
      end

      # Reset embedders setting to its default.
      #
      # @see #embedders
      # @return [Models::Task] The async update task that does the reset.
      def reset_embedders
        response = http_delete("/indexes/#{@uid}/settings/embedders")

        Models::Task.new(response, task_endpoint)
      end
    end

    include Settings
  end
end
