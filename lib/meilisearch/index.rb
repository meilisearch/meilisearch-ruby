# frozen_string_literal: true

require 'meilisearch/http_request'

module Meilisearch
  # Manages a Meilisearch indexes.
  #   index = client.index(INDEX_UID)
  #
  # Indexes store documents to be searched.
  # @see https://www.meilisearch.com/docs/learn/getting_started/indexes Learn more about indexes
  class Index < HTTPRequest
    attr_reader :uid, :primary_key, :created_at, :updated_at

    def initialize(index_uid, url, api_key = nil, primary_key = nil, options = {})
      @uid = index_uid
      @primary_key = primary_key
      super(url, api_key, options)
    end

    # Fetch the latest info about the index from the Meilisearch instance and return self.
    #
    # @see https://www.meilisearch.com/docs/reference/api/indexes#get-one-index Meilisearch API Reference
    # @return [self]
    def fetch_info
      index_hash = http_get indexes_path(id: @uid)
      set_base_properties index_hash
      self
    end

    # Fetch the latest info about the index from the Meilisearch instance and return the primary key.
    #
    # @see https://www.meilisearch.com/docs/reference/api/indexes#get-one-index Meilisearch API Reference
    # @return [String]
    def fetch_primary_key
      fetch_info.primary_key
    end
    alias get_primary_key fetch_primary_key

    # Fetch the latest info about the index from the Meilisearch instance and return the raw hash.
    #
    # @see https://www.meilisearch.com/docs/reference/api/indexes#get-one-index Meilisearch API Reference
    # @return [Hash{String => String}]
    def fetch_raw_info
      index_hash = http_get indexes_path(id: @uid)
      set_base_properties index_hash
      index_hash
    end

    # Update index primary key.
    #
    #   client.index('movies').update(primary_key: 'movie_id')
    #
    # It is not possible to rename indexes, see {Client#swap_indexes} instead.
    #
    # @see https://www.meilisearch.com/docs/reference/api/indexes#update-an-index Meilisearch API Reference
    # @param  body [Hash{String => String}] The options hash to update the index, including a +:primary_key+ key
    # @return [Models::Task] The task that updates the primary key.
    def update(body)
      response = http_patch indexes_path(id: @uid), Utils.transform_attributes(body)
      Models::Task.new(response, task_endpoint)
    end

    alias update_index update

    # Delete index
    #
    # @see https://www.meilisearch.com/docs/reference/api/indexes#delete-an-index Meilisearch API Reference
    def delete
      response = http_delete indexes_path(id: @uid)
      Models::Task.new(response, task_endpoint)
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

    # Get a document, optionally limiting fields.
    #
    # @param document_id [String, Integer] The ID of the document to fetch
    # @param fields [nil, Array<Symbol>] Fields to fetch from the document, defaults to all
    # @return [nil, Hash{String => Object}] The requested document.
    # @see https://www.meilisearch.com/docs/reference/api/documents#get-one-document Meilisearch API Reference
    def document(document_id, fields: nil)
      encode_document = URI.encode_www_form_component(document_id)
      body = { fields: fields&.join(',') }.compact

      http_get("/indexes/#{@uid}/documents/#{encode_document}", body)
    end
    alias get_document document
    alias get_one_document document

    # Retrieve documents from a index.
    #
    # @param options [Hash{Symbol => Object}] The hash options used to refine the selection (default: {}):
    #           :limit  - Number of documents to return (optional).
    #           :offset - Number of documents to skip (optional).
    #           :fields - Array of document attributes to show (optional).
    #           :filter - Filter queries by an attribute's value.
    #                     Available ONLY with Meilisearch v1.2 and newer (optional).
    #           :sort   - A list of attributes written as an array or as a comma-separated string (optional)
    #           :ids    - Array of ids to be retrieved (optional)
    #
    # @return [Hash{String => Object}] The documents results object.
    # @see https://www.meilisearch.com/docs/reference/api/documents#get-documents-with-post Meilisearch API Reference
    def documents(options = {})
      Utils.version_error_handler(__method__) do
        if options.key?(:filter)
          http_post "/indexes/#{@uid}/documents/fetch", Utils.filter(options, [:limit, :offset, :fields, :filter, :sort, :ids])
        else
          http_get "/indexes/#{@uid}/documents", Utils.parse_query(options, [:limit, :offset, :fields, :sort, :ids])
        end
      end
    end
    alias get_documents documents

    # Add documents to an index.
    #
    # Documents that already exist in the index are overwritten, with missing fields removed. Identitiy is checked by the value of the primary key field.
    #
    #   client.index('movies').add_documents([
    #     {
    #      id: 287947,
    #      title: 'Shazam',
    #      poster: 'https://image.tmdb.org/t/p/w1280/xnopI5Xtky18MPhK40cZAGAOVeV.jpg',
    #      overview: 'A boy is given the ability to become an adult superhero in times of need with a single magic word.',
    #      release_date: '2019-03-23'
    #     }
    #   ])
    #
    # @param documents [Array<Hash{Object => Object>}] The documents to be added.
    # @param primary_key [String] The name of the primary key field, auto inferred if missing.
    #
    # @return [Models::Task] The async task that adds the documents.
    # @see https://www.meilisearch.com/docs/reference/api/documents#add-or-replace-documents Meilisearch API Reference
    def add_documents(documents, primary_key = nil)
      documents = [documents] if documents.is_a?(Hash)
      response = http_post "/indexes/#{@uid}/documents", documents, { primaryKey: primary_key }.compact

      Models::Task.new(response, task_endpoint)
    end
    alias replace_documents add_documents
    alias add_or_replace_documents add_documents

    # Synchronous version of {#add_documents}.
    #
    # @deprecated
    #   use {Models::Task#await} on task returned from {#add_documents}
    #
    #     index.add_documents(...).await
    #
    # Waits for the task to be achieved with a busy loop, be careful when using it.
    def add_documents!(documents, primary_key = nil)
      Utils.soft_deprecate(
        'Index#add_documents!',
        'index.add_documents(...).await'
      )

      add_documents(documents, primary_key).await
    end
    alias replace_documents! add_documents!
    alias add_or_replace_documents! add_documents!

    # Add or replace documents from a JSON string.
    #
    # Documents that already exist in the index are overwritten, with missing fields removed. Identitiy is checked by the value of the primary key field.
    #
    # @param documents [String] JSON document that includes your documents.
    # @param primary_key [String] The name of the primary key field, auto inferred if missing.
    #
    # @return [Models::Task] The async task that adds the documents.
    def add_documents_json(documents, primary_key = nil)
      options = { convert_body?: false }
      response = http_post "/indexes/#{@uid}/documents", documents, { primaryKey: primary_key }.compact, options

      Models::Task.new(response, task_endpoint)
    end
    alias replace_documents_json add_documents_json
    alias add_or_replace_documents_json add_documents_json

    # Add or replace documents from a NDJSON string.
    #
    # Documents that already exist in the index are overwritten, with missing fields removed. Identitiy is checked by the value of the primary key field.
    # Newline delimited JSON is a JSON specification that is easier to stream.
    #
    # @param documents [String] JSON document that includes your documents.
    # @param primary_key [String] The name of the primary key field, auto inferred if missing.
    #
    # @return [Models::Task] The async task that adds the documents.
    #
    # @see https://github.com/ndjson/ndjson-spec NDJSON spec
    def add_documents_ndjson(documents, primary_key = nil)
      options = { headers: { 'Content-Type' => 'application/x-ndjson' }, convert_body?: false }
      response = http_post "/indexes/#{@uid}/documents", documents, { primaryKey: primary_key }.compact, options

      Models::Task.new(response, task_endpoint)
    end
    alias replace_documents_ndjson add_documents_ndjson
    alias add_or_replace_documents_ndjson add_documents_ndjson

    # Add or replace documents from a CSV string.
    #
    # Documents that already exist in the index are overwritten, with missing fields removed. Identitiy is checked by the value of the primary key field.
    # CSV text is delimited by commas by default but Meilisearch allows specifying custom delimeters.
    #
    # @param documents [String] JSON document that includes your documents.
    # @param primary_key [String] The name of the primary key field, auto inferred if missing.
    # @param delimiter [String] The delimiter character in your CSV text.
    #
    # @return [Models::Task] The async task that adds the documents.
    def add_documents_csv(documents, primary_key = nil, delimiter = nil)
      options = { headers: { 'Content-Type' => 'text/csv' }, convert_body?: false }

      response = http_post "/indexes/#{@uid}/documents", documents, {
        primaryKey: primary_key,
        csvDelimiter: delimiter
      }.compact, options

      Models::Task.new(response, task_endpoint)
    end
    alias replace_documents_csv add_documents_csv
    alias add_or_replace_documents_csv add_documents_csv

    # Add documents to an index.
    #
    # Documents that already exist in the index are updated, with missing fields ignored. Identitiy is checked by the value of the primary key field.
    #
    # @param documents [Array<Hash{Object => Object>}] The documents to be added.
    # @param primary_key [String] The name of the primary key field, auto inferred if missing.
    #
    # @return [Models::Task] The async task that adds the documents.
    # @see https://www.meilisearch.com/docs/reference/api/documents#add-or-replace-documents Meilisearch API Reference
    def update_documents(documents, primary_key = nil)
      documents = [documents] if documents.is_a?(Hash)
      response = http_put "/indexes/#{@uid}/documents", documents, { primaryKey: primary_key }.compact

      Models::Task.new(response, task_endpoint)
    end
    alias add_or_update_documents update_documents

    # Add or update documents from a JSON string.
    #
    # Documents that already exist in the index are updated, with missing fields ignored. Identitiy is checked by the value of the primary key field.
    #
    # @param documents [String] JSON document that includes your documents.
    # @param primary_key [String] The name of the primary key field, auto inferred if missing.
    #
    # @return [Models::Task] The async task that adds the documents.
    def update_documents_json(documents, primary_key = nil)
      options = { convert_body?: false }
      response = http_put "/indexes/#{@uid}/documents", documents, { primaryKey: primary_key }.compact, options

      Models::Task.new(response, task_endpoint)
    end
    alias add_or_update_documents_json update_documents_json

    # Add or update documents from a NDJSON string.
    #
    # Documents that already exist in the index are updated, with missing fields ignored. Identitiy is checked by the value of the primary key field.
    # Newline delimited JSON is a JSON specification that is easier to stream.
    #
    # @param documents [String] JSON document that includes your documents.
    # @param primary_key [String] The name of the primary key field, auto inferred if missing.
    #
    # @return [Models::Task] The async task that adds the documents.
    #
    # @see https://github.com/ndjson/ndjson-spec NDJSON spec
    def update_documents_ndjson(documents, primary_key = nil)
      options = { headers: { 'Content-Type' => 'application/x-ndjson' }, convert_body?: false }
      response = http_put "/indexes/#{@uid}/documents", documents, { primaryKey: primary_key }.compact, options

      Models::Task.new(response, task_endpoint)
    end
    alias add_or_update_documents_ndjson update_documents_ndjson

    # Add or update documents from a CSV string.
    #
    # Documents that already exist in the index are updated, with missing fields ignored. Identitiy is checked by the value of the primary key field.
    # CSV text is delimited by commas by default but Meilisearch allows specifying custom delimeters.
    #
    # @param documents [String] JSON document that includes your documents.
    # @param primary_key [String] The name of the primary key field, auto inferred if missing.
    # @param delimiter [String] The delimiter character in your CSV text.
    #
    # @return [Models::Task] The async task that adds the documents.
    def update_documents_csv(documents, primary_key = nil, delimiter = nil)
      options = { headers: { 'Content-Type' => 'text/csv' }, convert_body?: false }

      response = http_put "/indexes/#{@uid}/documents", documents, {
        primaryKey: primary_key,
        csvDelimiter: delimiter
      }.compact, options

      Models::Task.new(response, task_endpoint)
    end
    alias add_or_update_documents_csv add_documents_csv

    # Batched version of {#update_documents_ndjson}
    #
    # @param documents [String] JSON document that includes your documents.
    # @param batch_size [Integer] The number of documents to update at a time.
    # @param primary_key [String] The name of the primary key field, auto inferred if missing.
    #
    # @return [Array<Models::Task>] An array of tasks for each batch.
    #
    # @see https://github.com/ndjson/ndjson-spec NDJSON spec
    def update_documents_ndjson_in_batches(documents, batch_size = 1000, primary_key = nil)
      documents.lines.each_slice(batch_size).map do |batch|
        update_documents_ndjson(batch.join, primary_key)
      end
    end

    # Batched version of {#update_documents_csv}.
    #
    # @param documents [String] JSON document that includes your documents.
    # @param batch_size [Integer] The number of documents to update at a time.
    # @param primary_key [String] The name of the primary key field, auto inferred if missing.
    # @param delimiter [String] The delimiter character in your CSV text.
    #
    # @return [Array<Models::Task>] An array of tasks for each batch.
    def update_documents_csv_in_batches(documents, batch_size = 1000, primary_key = nil, delimiter = nil)
      lines = documents.lines
      heading = lines.first
      lines.drop(1).each_slice(batch_size).map do |batch|
        update_documents_csv(heading + batch.join, primary_key, delimiter)
      end
    end

    # Synchronous version of {#update_documents}.
    #
    # @deprecated
    #   use {Models::Task#await} on task returned from {#update_documents}
    #
    #     index.update_documents(...).await
    #
    # Waits for the task to be achieved with a busy loop, be careful when using it.
    def update_documents!(documents, primary_key = nil)
      Utils.soft_deprecate(
        'Index#update_documents!',
        'index.update_documents(...).await'
      )

      update_documents(documents, primary_key).await
    end
    alias add_or_update_documents! update_documents!

    # Batched version of {#add_documents}.
    #
    # @param documents [String] JSON document that includes your documents.
    # @param batch_size [Integer] The number of documents to update at a time.
    # @param primary_key [String] The name of the primary key field, auto inferred if missing.
    #
    # @return [Array<Models::Task>] An array of tasks for each batch.
    def add_documents_in_batches(documents, batch_size = 1000, primary_key = nil)
      documents.each_slice(batch_size).map do |batch|
        add_documents(batch, primary_key)
      end
    end

    # Batched version of {#add_documents_ndjson}.
    #
    # @param documents [String] JSON document that includes your documents.
    # @param batch_size [Integer] The number of documents to update at a time.
    # @param primary_key [String] The name of the primary key field, auto inferred if missing.
    #
    # @return [Array<Models::Task>] An array of tasks for each batch.
    def add_documents_ndjson_in_batches(documents, batch_size = 1000, primary_key = nil)
      documents.lines.each_slice(batch_size).map do |batch|
        add_documents_ndjson(batch.join, primary_key)
      end
    end

    # Batched version of {#add_documents_csv}.
    #
    # @param documents [String] JSON document that includes your documents.
    # @param batch_size [Integer] The number of documents to update at a time.
    # @param primary_key [String] The name of the primary key field, auto inferred if missing.
    # @param delimiter [String] The delimiter character in your CSV text.
    #
    # @return [Array<Models::Task>] An array of tasks for each batch.
    def add_documents_csv_in_batches(documents, batch_size = 1000, primary_key = nil, delimiter = nil)
      lines = documents.lines
      heading = lines.first
      lines.drop(1).each_slice(batch_size).map do |batch|
        add_documents_csv(heading + batch.join, primary_key, delimiter)
      end
    end

    # Synchronous version of {#add_documents_in_batches}.
    #
    # @deprecated
    #   use {Models::Task#await} on task returned from {#add_documents_in_batches}
    #
    #     index.add_documents_in_batches(...).await
    #
    # Waits for the task to be achieved with a busy loop, be careful when using it.
    def add_documents_in_batches!(documents, batch_size = 1000, primary_key = nil)
      Utils.soft_deprecate(
        'Index#add_documents_in_batches!',
        'index.add_documents_in_batches(...).each(&:await)'
      )

      add_documents_in_batches(documents, batch_size, primary_key).each(&:await)
    end

    # Batched version of {#update_documents}.
    #
    # @param documents [String] JSON document that includes your documents.
    # @param batch_size [Integer] The number of documents to update at a time.
    # @param primary_key [String] The name of the primary key field, auto inferred if missing.
    #
    # @return [Array<Models::Task>] An array of tasks for each batch.
    def update_documents_in_batches(documents, batch_size = 1000, primary_key = nil)
      documents.each_slice(batch_size).map do |batch|
        update_documents(batch, primary_key)
      end
    end

    # Synchronous version of {#update_documents_in_batches}.
    #
    # @deprecated
    #   use {Models::Task#await} on task returned from {#update_documents_in_batches}
    #
    #     index.update_documents_in_batches(...).await
    #
    # Waits for the task to be achieved with a busy loop, be careful when using it.
    def update_documents_in_batches!(documents, batch_size = 1000, primary_key = nil)
      Utils.soft_deprecate(
        'Index#update_documents_in_batches!',
        'index.update_documents_in_batches(...).each(&:await)'
      )

      update_documents_in_batches(documents, batch_size, primary_key).each(&:await)
    end

    # Update documents by function
    #
    # @param options [Hash{String => Object}]
    #
    # @see https://www.meilisearch.com/docs/reference/api/documents#update-documents-with-function Meilisearch API Documentation
    def update_documents_by_function(options)
      response = http_post "/indexes/#{@uid}/documents/edit", options

      Models::Task.new(response, task_endpoint)
    end

    # Delete documents from an index.
    #
    #   index.delete_documents([1, 2, 3, 4])
    #   index.delete_documents({ filter: "age > 10" })
    #
    # @param options [Array<[String, Integer]>, Hash{Symbol => String}] A Hash or an Array containing documents_ids or a hash with filter: key.
    #   filter: - A hash containing a filter that should match documents.
    #             Available ONLY with Meilisearch v1.2 and newer (optional)
    #
    # @return [Models::Task] An object representing the async deletion task.
    def delete_documents(options = {})
      Utils.version_error_handler(__method__) do
        response = if options.is_a?(Hash) && options.key?(:filter)
                     http_post "/indexes/#{@uid}/documents/delete", options
                   else
                     # backwards compatibility:
                     # expect to be a array or/number/string to send alongside as documents_ids.
                     options = [options] unless options.is_a?(Array)

                     http_post "/indexes/#{@uid}/documents/delete-batch", options
                   end

        Models::Task.new(response, task_endpoint)
      end
    end
    alias delete_multiple_documents delete_documents

    # Synchronous version of {#delete_documents}.
    #
    # @deprecated
    #   use {Models::Task#await} on task returned from {#delete_documents}
    #
    #     index.delete_documents(...).await
    #
    # Waits for the task to be achieved with a busy loop, be careful when using it.
    def delete_documents!(documents_ids)
      Utils.soft_deprecate(
        'Index#delete_documents!',
        'index.delete_documents(...).await'
      )

      delete_documents(documents_ids).await
    end
    alias delete_multiple_documents! delete_documents!

    # Delete a single document by id.
    #
    #   index.delete_document(15)
    #
    # @param document_id [String, Integer] The ID of the document to delete.
    #
    # @return [Models::Task] An object representing the async deletion task.
    def delete_document(document_id)
      if document_id.nil? || document_id.to_s.empty?
        raise Meilisearch::InvalidDocumentId, 'document_id cannot be empty or nil'
      end

      encode_document = URI.encode_www_form_component(document_id)
      response = http_delete "/indexes/#{@uid}/documents/#{encode_document}"

      Models::Task.new(response, task_endpoint)
    end
    alias delete_one_document delete_document

    # Synchronous version of {#delete_document}.
    #
    # @deprecated
    #   use {Models::Task#await} on task returned from {#delete_document}
    #
    #     index.delete_document(...).await
    #
    # Waits for the task to be achieved with a busy loop, be careful when using it.
    def delete_document!(document_id)
      Utils.soft_deprecate(
        'Index#delete_document!',
        'index.delete_document(...).await'
      )

      delete_document(document_id).await
    end
    alias delete_one_document! delete_document!

    # Delete all documents in the index.
    #
    #   index.delete_all_documents
    #
    # @return [Models::Task] An object representing the async deletion task.
    def delete_all_documents
      response = http_delete "/indexes/#{@uid}/documents"
      Models::Task.new(response, task_endpoint)
    end

    # Synchronous version of {#delete_all_documents}.
    #
    # @deprecated
    #   use {Models::Task#await} on task returned from {#delete_all_documents}
    #
    #     index.delete_all_documents(...).await
    #
    # Waits for the task to be achieved with a busy loop, be careful when using it.
    def delete_all_documents!
      Utils.soft_deprecate(
        'Index#delete_all_documents!',
        'index.delete_all_documents(...).await'
      )

      delete_all_documents.await
    end

    ### SEARCH

    # Run a search on this index.
    #
    # Check Meilisearch API Reference for all options.
    #
    # @param query [String] The query string for the search.
    # @param options [Hash{Symbol => Object}] Search options.
    #
    # @return [Hash{String => Object}] Search results
    # @see https://www.meilisearch.com/docs/reference/api/search#search-in-an-index-with-post Meilisearch API Reference
    def search(query, options = {})
      attributes = { q: query.to_s }.merge(options.compact)

      parsed_options = Utils.transform_attributes(attributes)
      response = http_post "/indexes/#{@uid}/search", parsed_options

      response['nbHits'] ||= response['estimatedTotalHits'] unless response.key?('totalPages')

      response
    end

    # Run a search for semantically similar documents.
    #
    # An embedder must be configured and specified.
    # Check Meilisearch API Reference for all options.
    #
    # @param document_id [String, Integer] The base document for comparisons.
    # @param options [Hash{Symbol => Object}] Search options. Including a mandatory :embedder option.
    #
    # @return [Hash{String => Object}] Search results
    # @see https://www.meilisearch.com/docs/reference/api/similar#get-similar-documents-with-post Meilisearch API Reference
    def search_similar_documents(document_id, **options)
      options.merge!(id: document_id)
      options = Utils.transform_attributes(options)

      http_post("/indexes/#{@uid}/similar", options)
    end

    ### FACET SEARCH

    # Search for facet values.
    #
    #   client.index('books').facet_search('genres', 'fiction', filter: 'rating > 3')
    #   # {
    #   #   "facetHits": [
    #   #     {
    #   #       "value": "fiction",
    #   #       "count": 7
    #   #     }
    #   #   ],
    #   #   "facetQuery": "fiction",
    #   #   "processingTimeMs": 0
    #   # }
    #
    # @param name [String] Facet name to search values on.
    # @param query [String] Search query for a given facet value.
    # @param options [Hash{Symbol => Object}] Additional options, see API Reference.
    # @return [Hash{String => Object}] Facet search result.
    #
    # @see https://www.meilisearch.com/docs/reference/api/facet_search Meilisearch API Reference
    def facet_search(name, query = '', **options)
      options.merge!(facet_name: name, facet_query: query)
      options = Utils.transform_attributes(options)

      http_post("/indexes/#{@uid}/facet-search", options)
    end

    ### TASKS

    def task_endpoint
      @task_endpoint ||= Task.new(@base_url, @api_key, @options)
    end
    private :task_endpoint

    # Get a task belonging to this index, in Hash form.
    #
    # @see Task#index_task
    def task(task_uid)
      task_endpoint.index_task(task_uid)
    end

    # Get all tasks belonging to this index, in Hash form.
    #
    # @see Task#index_tasks
    def tasks
      task_endpoint.index_tasks(@uid)
    end

    # Wait for a given task to finish in a busy loop.
    #
    # @see Task#wait_for_task
    def wait_for_task(task_uid, timeout_in_ms = 5000, interval_in_ms = 50)
      task_endpoint.wait_for_task(task_uid, timeout_in_ms, interval_in_ms)
    end

    ### STATS

    # Get stats of this index.
    #
    # @return [Hash{String => Object}]
    # @see https://www.meilisearch.com/docs/reference/api/stats#get-stats-of-an-index  Meilisearch API Reference
    def stats
      http_get "/indexes/#{@uid}/stats"
    end

    # Get the number of documents in the index.
    #
    # Calls {#stats}
    #
    # @return [Integer]
    def number_of_documents
      stats['numberOfDocuments']
    end

    # Whether the index is currently in the middle of indexing documents.
    #
    # Calls {#stats}
    # @return [Boolean]
    def indexing?
      stats['isIndexing']
    end

    # Get the filed distribution of documents in the index.
    #
    # Calls {#stats}
    def field_distribution
      stats['fieldDistribution']
    end

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
end
