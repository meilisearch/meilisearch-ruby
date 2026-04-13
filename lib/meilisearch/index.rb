# frozen_string_literal: true

require 'meilisearch/http_request'

module Meilisearch
  # Manages a Meilisearch indexes.
  #   index = client.index(INDEX_UID)
  #
  # Indexes store documents to be searched.
  # @see https://www.meilisearch.com/docs/learn/getting_started/indexes Learn more about indexes
  class Index < HTTPRequest
    require 'meilisearch/index/compact'
    require 'meilisearch/index/documents'
    require 'meilisearch/index/facet_search'
    require 'meilisearch/index/search'
    require 'meilisearch/index/settings'
    require 'meilisearch/index/stats'

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

    # Update index uid (rename) and/or primary key.
    #
    # Rename an index by providing a new uid:
    #   client.index('movies').update(uid: 'films')
    #
    # Update the primary key:
    #   client.index('movies').update(primary_key: 'movie_id')
    #
    # Or do both at once:
    #   client.index('movies').update(uid: 'films', primary_key: 'movie_id')
    #
    # When renaming an index, all documents, settings, and stats are preserved.
    # Renaming fails if the target uid already exists, the index is missing, or the uid format is invalid.
    #
    # To swap the names of two indexes atomically, see {Client#swap_indexes} instead.
    #
    # @see https://www.meilisearch.com/docs/reference/api/indexes#update-an-index Meilisearch API Reference
    # @param  body [Hash{String => String}] The options hash to update the index
    # @option body [String] :uid The new uid for the index (to rename it)
    # @option body [String] :primary_key The new primary key for the index
    # @return [Models::Task] Task tracking the update
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

    private

    def indexes_path(id: nil)
      "/indexes/#{id}"
    end

    def set_base_properties(index_hash)
      @primary_key = index_hash['primaryKey']
      @created_at = Time.parse(index_hash['createdAt'])
      @updated_at = Time.parse(index_hash['updatedAt'])
    end

    def task_endpoint
      @task_endpoint ||= Task.new(@base_url, @api_key, @options)
    end
  end
end
