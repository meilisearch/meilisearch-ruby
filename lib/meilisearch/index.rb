# frozen_string_literal: true

require 'meilisearch/http_request'
require 'timeout'

module MeiliSearch
  class Index < HTTPRequest
    attr_reader :uid, :primary_key

    def initialize(index_uid, url, api_key = nil, primary_key = nil, options = {})
      @uid = index_uid
      @primary_key = primary_key
      super(url, api_key, options)
    end

    def fetch_info
      index_hash = http_get "/indexes/#{@uid}"
      @primary_key = index_hash['primaryKey']
      self
    end

    def update(body)
      index_hash = http_put "/indexes/#{@uid}", body
      @primary_key = index_hash['primaryKey']
      self
    end
    alias update_index update

    def delete
      http_delete "/indexes/#{@uid}"
    end
    alias delete_index delete

    def fetch_primary_key
      fetch_info.primary_key
    end
    alias get_primary_key fetch_primary_key

    ### DOCUMENTS

    def document(document_id)
      encode_document = URI.encode_www_form_component(document_id)
      http_get "/indexes/#{@uid}/documents/#{encode_document}"
    end
    alias get_document document
    alias get_one_document document

    def documents(options = {})
      http_get "/indexes/#{@uid}/documents", options
    end
    alias get_documents documents

    def add_documents(documents, primary_key = nil)
      documents = [documents] if documents.is_a?(Hash)
      http_post "/indexes/#{@uid}/documents", documents, { primaryKey: primary_key }.compact
    end
    alias replace_documents add_documents
    alias add_or_replace_documents add_documents

    def update_documents(documents, primary_key = nil)
      documents = [documents] if documents.is_a?(Hash)
      http_put "/indexes/#{@uid}/documents", documents, { primaryKey: primary_key }.compact
    end
    alias add_or_update_documents update_documents

    def delete_documents(documents_ids)
      if documents_ids.is_a?(Array)
        http_post "/indexes/#{@uid}/documents/delete-batch", documents_ids
      else
        delete_document(documents_ids)
      end
    end
    alias delete_multiple_documents delete_documents

    def delete_document(document_id)
      encode_document = URI.encode_www_form_component(document_id)
      http_delete "/indexes/#{@uid}/documents/#{encode_document}"
    end
    alias delete_one_document delete_document

    def delete_all_documents
      http_delete "/indexes/#{@uid}/documents"
    end

    ### SEARCH

    def search(query, options = {})
      parsed_options = options.compact
      http_post "/indexes/#{@uid}/search", { q: query }.merge(parsed_options)
    end

    ### UPDATES

    def get_update_status(update_id)
      http_get "/indexes/#{@uid}/updates/#{update_id}"
    end

    def get_all_update_status
      http_get "/indexes/#{@uid}/updates"
    end

    def wait_for_pending_update(update_id, timeout_in_ms = 5000, interval_in_ms = 50)
      Timeout.timeout(timeout_in_ms.to_f / 1000) do
        loop do
          get_update = get_update_status(update_id)
          return get_update if get_update['status'] != 'enqueued'

          sleep interval_in_ms.to_f / 1000
        end
      end
    rescue Timeout::Error
      raise MeiliSearch::TimeoutError
    end

    ### STATS

    def stats
      http_get "/indexes/#{@uid}/stats"
    end

    def number_of_documents
      stats['numberOfDocuments']
    end

    def indexing?
      stats['isIndexing']
    end

    def last_update
      stats['lastUpdate']
    end

    def fields_distribution
      stats['fieldsDistribution']
    end

    ### SETTINGS - GENERAL

    def settings
      http_get "/indexes/#{@uid}/settings"
    end
    alias get_settings settings

    def update_settings(settings)
      http_post "/indexes/#{@uid}/settings", settings
    end
    alias settings= update_settings

    def reset_settings
      http_delete "/indexes/#{@uid}/settings"
    end

    ### SETTINGS - RANKING RULES

    def ranking_rules
      http_get "/indexes/#{@uid}/settings/ranking-rules"
    end
    alias get_ranking_rules ranking_rules

    def update_ranking_rules(ranking_rules)
      http_post "/indexes/#{@uid}/settings/ranking-rules", ranking_rules
    end
    alias ranking_rules= update_ranking_rules

    def reset_ranking_rules
      http_delete "/indexes/#{@uid}/settings/ranking-rules"
    end

    ### SETTINGS - SYNONYMS

    def synonyms
      http_get "/indexes/#{@uid}/settings/synonyms"
    end
    alias get_synonyms synonyms

    def update_synonyms(synonyms)
      http_post "/indexes/#{@uid}/settings/synonyms", synonyms
    end
    alias synonyms= update_synonyms

    def reset_synonyms
      http_delete "/indexes/#{@uid}/settings/synonyms"
    end

    ### SETTINGS - STOP-WORDS

    def stop_words
      http_get "/indexes/#{@uid}/settings/stop-words"
    end
    alias get_stop_words stop_words

    def update_stop_words(stop_words)
      body = stop_words.is_a?(Array) ? stop_words : [stop_words]
      http_post "/indexes/#{@uid}/settings/stop-words", body
    end
    alias stop_words= update_stop_words

    def reset_stop_words
      http_delete "/indexes/#{@uid}/settings/stop-words"
    end

    ### SETTINGS - DINSTINCT ATTRIBUTE

    def distinct_attribute
      http_get "/indexes/#{@uid}/settings/distinct-attribute"
    end
    alias get_distinct_attribute distinct_attribute

    def update_distinct_attribute(distinct_attribute)
      http_post "/indexes/#{@uid}/settings/distinct-attribute", distinct_attribute
    end
    alias distinct_attribute= update_distinct_attribute

    def reset_distinct_attribute
      http_delete "/indexes/#{@uid}/settings/distinct-attribute"
    end

    ### SETTINGS - SEARCHABLE ATTRIBUTES

    def searchable_attributes
      http_get "/indexes/#{@uid}/settings/searchable-attributes"
    end
    alias get_searchable_attributes searchable_attributes

    def update_searchable_attributes(searchable_attributes)
      http_post "/indexes/#{@uid}/settings/searchable-attributes", searchable_attributes
    end
    alias searchable_attributes= update_searchable_attributes

    def reset_searchable_attributes
      http_delete "/indexes/#{@uid}/settings/searchable-attributes"
    end

    ### SETTINGS - DISPLAYED ATTRIBUTES

    def displayed_attributes
      http_get "/indexes/#{@uid}/settings/displayed-attributes"
    end
    alias get_displayed_attributes displayed_attributes

    def update_displayed_attributes(displayed_attributes)
      http_post "/indexes/#{@uid}/settings/displayed-attributes", displayed_attributes
    end
    alias displayed_attributes= update_displayed_attributes

    def reset_displayed_attributes
      http_delete "/indexes/#{@uid}/settings/displayed-attributes"
    end

    ### SETTINGS - ATTRIBUTES FOR FACETING

    def attributes_for_faceting
      http_get "/indexes/#{@uid}/settings/attributes-for-faceting"
    end
    alias get_attributes_for_faceting attributes_for_faceting

    def update_attributes_for_faceting(attributes_for_faceting)
      http_post "/indexes/#{@uid}/settings/attributes-for-faceting", attributes_for_faceting
    end
    alias attributes_for_faceting= update_attributes_for_faceting

    def reset_attributes_for_faceting
      http_delete "/indexes/#{@uid}/settings/attributes-for-faceting"
    end
  end
end
