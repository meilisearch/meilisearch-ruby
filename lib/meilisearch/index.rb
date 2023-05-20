# frozen_string_literal: true

require 'meilisearch/http_request'

module MeiliSearch
  class Index < HTTPRequest
    attr_reader :uid, :primary_key, :created_at, :updated_at

    def initialize(index_uid, url, api_key = nil, primary_key = nil, options = {})
      @uid = index_uid
      @primary_key = primary_key
      super(url, api_key, options)
    end

    def fetch_info
      index_hash = http_get indexes_path(id: @uid)
      set_base_properties index_hash
      self
    end

    def fetch_primary_key
      fetch_info.primary_key
    end
    alias get_primary_key fetch_primary_key

    def fetch_raw_info
      index_hash = http_get indexes_path(id: @uid)
      set_base_properties index_hash
      index_hash
    end

    def update(body)
      http_patch indexes_path(id: @uid), Utils.transform_attributes(body)
    end

    alias update_index update

    def delete
      http_delete indexes_path(id: @uid)
    end
    alias delete_index delete

    def indexes_path(id: nil)
      "/indexes/#{id}"
    end
    private :indexes_path

    def set_base_properties(index_hash)
      @primary_key = index_hash['primaryKey']
      @created_at = Time.parse(index_hash['createdAt'])
      @updated_at = Time.parse(index_hash['updatedAt'])
    end
    private :set_base_properties

    ### DOCUMENTS

    def document(document_id, fields: nil)
      encode_document = URI.encode_www_form_component(document_id)
      body = { fields: fields&.join(',') }.compact

      http_get("/indexes/#{@uid}/documents/#{encode_document}", body)
    end
    alias get_document document
    alias get_one_document document

    def documents(options = {})
      http_get "/indexes/#{@uid}/documents", Utils.parse_query(options, [:limit, :offset, :fields])
    end
    alias get_documents documents

    def add_documents(documents, primary_key = nil)
      documents = [documents] if documents.is_a?(Hash)
      http_post "/indexes/#{@uid}/documents", documents, { primaryKey: primary_key }.compact
    end
    alias replace_documents add_documents
    alias add_or_replace_documents add_documents

    def add_documents!(documents, primary_key = nil)
      task = add_documents(documents, primary_key)
      wait_for_task(task['taskUid'])
    end
    alias replace_documents! add_documents!
    alias add_or_replace_documents! add_documents!

    def add_documents_json(documents, primary_key = nil)
      options = { convert_body?: false }
      http_post "/indexes/#{@uid}/documents", documents, { primaryKey: primary_key }.compact, options
    end
    alias replace_documents_json add_documents_json
    alias add_or_replace_documents_json add_documents_json

    def add_documents_ndjson(documents, primary_key = nil)
      options = { headers: { 'Content-Type' => 'application/x-ndjson' }, convert_body?: false }
      http_post "/indexes/#{@uid}/documents", documents, { primaryKey: primary_key }.compact, options
    end
    alias replace_documents_ndjson add_documents_ndjson
    alias add_or_replace_documents_ndjson add_documents_ndjson

    def add_documents_csv(documents, primary_key = nil, delimiter = nil)
      options = { headers: { 'Content-Type' => 'text/csv' }, convert_body?: false }

      http_post "/indexes/#{@uid}/documents", documents, {
        primaryKey: primary_key,
        csvDelimiter: delimiter
      }.compact, options
    end
    alias replace_documents_csv add_documents_csv
    alias add_or_replace_documents_csv add_documents_csv

    def update_documents(documents, primary_key = nil)
      documents = [documents] if documents.is_a?(Hash)
      http_put "/indexes/#{@uid}/documents", documents, { primaryKey: primary_key }.compact
    end
    alias add_or_update_documents update_documents

    def update_documents!(documents, primary_key = nil)
      task = update_documents(documents, primary_key)
      wait_for_task(task['taskUid'])
    end
    alias add_or_update_documents! update_documents!

    def add_documents_in_batches(documents, batch_size = 1000, primary_key = nil)
      tasks = []
      documents.each_slice(batch_size) do |batch|
        tasks.append(add_documents(batch, primary_key))
      end
      tasks
    end

    def add_documents_in_batches!(documents, batch_size = 1000, primary_key = nil)
      tasks = add_documents_in_batches(documents, batch_size, primary_key)
      responses = []
      tasks.each do |task_obj|
        responses.append(wait_for_task(task_obj['taskUid']))
      end
      responses
    end

    def update_documents_in_batches(documents, batch_size = 1000, primary_key = nil)
      tasks = []
      documents.each_slice(batch_size) do |batch|
        tasks.append(update_documents(batch, primary_key))
      end
      tasks
    end

    def update_documents_in_batches!(documents, batch_size = 1000, primary_key = nil)
      tasks = update_documents_in_batches(documents, batch_size, primary_key)
      responses = []
      tasks.each do |task_obj|
        responses.append(wait_for_task(task_obj['taskUid']))
      end
      responses
    end

    # Public: Delete documents from an index
    #
    # documents_ids - An array with document ids (deprecated, optional)
    # filter - A hash containing a filter that should match documents.
    #          Available ONLY with Meilisearch v1.2 and newer (optional)
    #
    # Returns a Task object.
    def delete_documents(documents_ids = nil, filter: nil)
      MeiliSearch::Utils.version_error_handler(__method__) do
        if documents_ids.nil?
          http_post "/indexes/#{@uid}/documents/delete", { filter: filter }
        else
          documents_ids = [documents_ids] unless documents_ids.is_a?(Array)

          http_post "/indexes/#{@uid}/documents/delete-batch", documents_ids
        end
      end
    end
    alias delete_multiple_documents delete_documents

    def delete_documents!(documents_ids)
      task = delete_documents(documents_ids)
      wait_for_task(task['taskUid'])
    end
    alias delete_multiple_documents! delete_documents!

    def delete_document(document_id)
      encode_document = URI.encode_www_form_component(document_id)
      http_delete "/indexes/#{@uid}/documents/#{encode_document}"
    end
    alias delete_one_document delete_document

    def delete_document!(document_id)
      task = delete_document(document_id)
      wait_for_task(task['taskUid'])
    end
    alias delete_one_document! delete_document!

    def delete_all_documents
      http_delete "/indexes/#{@uid}/documents"
    end

    def delete_all_documents!
      task = delete_all_documents
      wait_for_task(task['taskUid'])
    end

    ### SEARCH

    def search(query, options = {})
      parsed_options = Utils.transform_attributes({ q: query.to_s }.merge(options.compact))

      response = http_post "/indexes/#{@uid}/search", parsed_options

      response['nbHits'] ||= response['estimatedTotalHits'] unless response.key?('totalPages')

      response
    end

    ### TASKS

    def task_endpoint
      @task_endpoint ||= Task.new(@base_url, @api_key, @options)
    end
    private :task_endpoint

    def task(task_uid)
      task_endpoint.index_task(task_uid)
    end

    def tasks
      task_endpoint.index_tasks(@uid)
    end

    def wait_for_task(task_uid, timeout_in_ms = 5000, interval_in_ms = 50)
      task_endpoint.wait_for_task(task_uid, timeout_in_ms, interval_in_ms)
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

    def field_distribution
      stats['fieldDistribution']
    end

    ### SETTINGS - GENERAL

    def settings
      http_get "/indexes/#{@uid}/settings"
    end
    alias get_settings settings

    def update_settings(settings)
      http_patch "/indexes/#{@uid}/settings", Utils.transform_attributes(settings)
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
      http_put "/indexes/#{@uid}/settings/ranking-rules", ranking_rules
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
      http_put "/indexes/#{@uid}/settings/synonyms", synonyms
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
      body = stop_words.nil? || stop_words.is_a?(Array) ? stop_words : [stop_words]
      http_put "/indexes/#{@uid}/settings/stop-words", body
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
      http_put "/indexes/#{@uid}/settings/distinct-attribute", distinct_attribute
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
      http_put "/indexes/#{@uid}/settings/searchable-attributes", searchable_attributes
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
      http_put "/indexes/#{@uid}/settings/displayed-attributes", displayed_attributes
    end
    alias displayed_attributes= update_displayed_attributes

    def reset_displayed_attributes
      http_delete "/indexes/#{@uid}/settings/displayed-attributes"
    end

    ### SETTINGS - FILTERABLE ATTRIBUTES

    def filterable_attributes
      http_get "/indexes/#{@uid}/settings/filterable-attributes"
    end
    alias get_filterable_attributes filterable_attributes

    def update_filterable_attributes(filterable_attributes)
      http_put "/indexes/#{@uid}/settings/filterable-attributes", filterable_attributes
    end
    alias filterable_attributes= update_filterable_attributes

    def reset_filterable_attributes
      http_delete "/indexes/#{@uid}/settings/filterable-attributes"
    end

    ### SETTINGS - SORTABLE ATTRIBUTES

    def sortable_attributes
      http_get "/indexes/#{@uid}/settings/sortable-attributes"
    end
    alias get_sortable_attributes sortable_attributes

    def update_sortable_attributes(sortable_attributes)
      http_put "/indexes/#{@uid}/settings/sortable-attributes", sortable_attributes
    end
    alias sortable_attributes= update_sortable_attributes

    def reset_sortable_attributes
      http_delete "/indexes/#{@uid}/settings/sortable-attributes"
    end

    ### SETTINGS - PAGINATION

    def pagination
      http_get("/indexes/#{@uid}/settings/pagination")
    end
    alias get_pagination pagination

    def update_pagination(pagination)
      http_patch "/indexes/#{@uid}/settings/pagination", pagination
    end
    alias pagination= update_sortable_attributes

    def reset_pagination
      http_delete "/indexes/#{@uid}/settings/pagination"
    end

    def typo_tolerance
      http_get("/indexes/#{@uid}/settings/typo-tolerance")
    end
    alias get_typo_tolerance typo_tolerance

    def update_typo_tolerance(typo_tolerance_attributes)
      attributes = Utils.transform_attributes(typo_tolerance_attributes)
      http_patch("/indexes/#{@uid}/settings/typo-tolerance", attributes)
    end
    alias typo_tolerance= update_typo_tolerance

    def reset_typo_tolerance
      http_delete("/indexes/#{@uid}/settings/typo-tolerance")
    end

    def faceting
      http_get("/indexes/#{@uid}/settings/faceting")
    end
    alias get_faceting faceting

    def update_faceting(faceting_attributes)
      attributes = Utils.transform_attributes(faceting_attributes)
      http_patch("/indexes/#{@uid}/settings/faceting", attributes)
    end
    alias faceting= update_faceting

    def reset_faceting
      http_delete("/indexes/#{@uid}/settings/faceting")
    end
  end
end
