# frozen_string_literal: true

module Meilisearch
  # Manages a connection to a Meilisearch server.
  #   client = Meilisearch::Client.new(MEILISEARCH_URL, MASTER_KEY, options)
  #
  # @see #indexes Managing search indexes
  # @see #keys Managing API keys
  # @see #stats View usage statistics
  # @see #tasks Managing ongoing tasks
  # @see #health Health checking
  # @see #create_dump
  # @see #create_snapshot
  class Client < HTTPRequest
    include Meilisearch::TenantToken
    include Meilisearch::MultiSearch

    ### INDEXES

    # Fetch indexes in instance, returning the raw server response.
    #
    # Unless you have a good reason to, {#indexes} should be used instead.
    #
    # @see #indexes
    # @see https://www.meilisearch.com/docs/reference/api/indexes#list-all-indexes Meilisearch API reference
    # @param options [Hash<Symbol, Any>] limit and offset options
    # @return [Hash<String, Any>]
    #   {index response object}[https://www.meilisearch.com/docs/reference/api/indexes#response]
    def raw_indexes(options = {})
      body = Utils.transform_attributes(options.transform_keys(&:to_sym).slice(:limit, :offset))

      http_get('/indexes', body)
    end

    # Swap two indexes.
    #
    # Can be used as a convenient way to rebuild an index while keeping it operational.
    #   client.index('a_swap').add_documents({})
    #   client.swap_indexes(['a', 'a_swap'])
    #
    # Multiple swaps may be done with one request:
    #   client.swap_indexes(['a', 'a_swap'], ['b', 'b_swap'])
    #
    # @see https://www.meilisearch.com/docs/reference/api/indexes#swap-indexes Meilisearch API reference
    #
    # @param options [Array<Array(String, String)>] the indexes to swap
    # @return [Models::Task] the async task that swaps the indexes
    # @raise [ApiError]
    def swap_indexes(*options)
      mapped_array = options.map { |arr| { indexes: arr } }

      response = http_post '/swap-indexes', mapped_array
      Models::Task.new(response, task_endpoint)
    end

    # Fetch indexes in instance.
    #
    # @see https://www.meilisearch.com/docs/reference/api/indexes#list-all-indexes Meilisearch API reference
    # @param options [Hash<Symbol, Any>] limit and offset options
    # @return [Hash<String, Any>]
    #   {index response object}[https://www.meilisearch.com/docs/reference/api/indexes#response]
    #   with results mapped to instances of {Index}
    def indexes(options = {})
      response = raw_indexes(options)

      response['results'].map! do |index_hash|
        index_object(index_hash['uid'], index_hash['primaryKey'])
      end

      response
    end

    # Create a new empty index.
    #
    #   client.create_index('indexUID')
    #   client.create_index('indexUID', primary_key: 'id')
    #
    # Indexes are also created when accessed:
    #
    #   client.index('new_index').add_documents({})
    #
    # @see #index
    # @see https://www.meilisearch.com/docs/reference/api/indexes#create-an-index Meilisearch API reference
    #
    # @param index_uid [String] the uid of the new index
    # @param options [Hash<Symbol, Any>, nil] snake_cased options of {the endpoint}[https://www.meilisearch.com/docs/reference/api/indexes#create-an-index]
    #
    # @raise [ApiError]
    # @return [Models::Task] the async task that creates the index
    def create_index(index_uid, options = {})
      body = Utils.transform_attributes(options.merge(uid: index_uid))

      response = http_post '/indexes', body

      Models::Task.new(response, task_endpoint)
    end

    # Synchronous version of {#create_index}.
    #
    # @deprecated
    #   use {Models::Task#await} on task returned from {#create_index}
    #
    #     client.create_index('foo').await
    #
    # Waits for the task to be achieved with a busy loop, be careful when using it.
    def create_index!(index_uid, options = {})
      Utils.soft_deprecate(
        'Client#create_index!',
        "client.create_index('#{index_uid}').await"
      )

      create_index(index_uid, options).await
    end

    # Delete an index.
    #
    # @param index_uid [String] the uid of the index to be deleted
    # @return [Models::Task] the async task deleting the index
    def delete_index(index_uid)
      index_object(index_uid).delete
    end

    # Get index with given uid.
    #
    # Indexes that don't exist are lazily created by Meilisearch.
    #   index = client.index('index_uid')
    #   index.add_documents({}) # index is created here if it did not exist
    #
    # @see Index
    # @param index_uid [String] the uid of the index to get
    # @return [Index]
    def index(index_uid)
      index_object(index_uid)
    end

    # Shorthand for
    #  client.index(index_uid).fetch_info
    #
    # @see Index#fetch_info
    # @param index_uid [String] uid of the index
    def fetch_index(index_uid)
      index_object(index_uid).fetch_info
    end

    # Shorthand for
    #  client.index(index_uid).fetch_raw_info
    #
    # @see Index#fetch_raw_info
    # @param index_uid [String] uid of the index
    def fetch_raw_index(index_uid)
      index_object(index_uid).fetch_raw_info
    end

    ### KEYS

    # Get all API keys
    #
    # This and other key methods require that the Meilisearch instance have a
    # {master key}[https://www.meilisearch.com/docs/learn/security/differences_master_api_keys#master-key]
    # set.
    #
    # @see #create_key #create_key to create keys and set their scope
    # @see #key #key to fetch one key
    # @see https://www.meilisearch.com/docs/reference/api/keys#get-all-keys Meilisearch API reference
    # @param limit [String, Integer, nil] limit the number of returned keys
    # @param offset [String, Integer, nil] skip the first +offset+ keys,
    #   useful for paging.
    #
    # @return [Hash<String, Any>] a {keys response}[https://www.meilisearch.com/docs/reference/api/keys#response]
    def keys(limit: nil, offset: nil)
      body = { limit: limit, offset: offset }.compact

      http_get '/keys', body
    end

    # Get a specific API key.
    #
    #   # obviously this example uid will not correspond to a key on your server
    #   # please replace it with your own key's uid
    #   uid = '6062abda-a5aa-4414-ac91-ecd7944c0f8d'
    #   client.key(uid)
    #
    # This and other key methods require that the Meilisearch instance have a
    # {master key}[https://www.meilisearch.com/docs/learn/security/differences_master_api_keys#master-key]
    # set.
    #
    # @see #keys #keys to get all keys in the instance
    # @see #create_key #create_key to create keys and set their scope
    # @see https://www.meilisearch.com/docs/reference/api/keys#get-one-key Meilisearch API reference
    # @param uid_or_key [String] either the uuidv4 that is the key's
    #   {uid}[https://www.meilisearch.com/docs/reference/api/keys#uid] or
    #   a hash of the uid and the master key that is the key's
    #   {key}[https://www.meilisearch.com/docs/reference/api/keys#key] field
    #
    # @return [Hash<String, Any>] a {key object}[https://www.meilisearch.com/docs/reference/api/keys#key-object]
    def key(uid_or_key)
      http_get "/keys/#{uid_or_key}"
    end

    # Create a new API key.
    #
    #   require 'date_core'
    #   ten_days_later = (DateTime.now + 10).rfc3339
    #   client.create_key(actions: ['*'], indexes: ['*'], expires_at: ten_days_later)
    #
    # This and other key methods require that the Meilisearch instance have a
    # {master key}[https://www.meilisearch.com/docs/learn/security/differences_master_api_keys#master-key]
    # set.
    #
    # @see #update_key #update_key to edit an existing key
    # @see #keys #keys to get all keys in the instance
    # @see #key #key to fetch one key
    # @see https://www.meilisearch.com/docs/reference/api/keys#create-a-key Meilisearch API reference
    # @param key_options [Hash<Symbol, Any>] the key options of which the required are
    #   - +:actions+ +Array+ of API actions allowed for key, +["*"]+ for all
    #   - +:indexes+ +Array+ of indexes key can act on, +["*"]+ for all
    #   - +:expires_at+ expiration datetime in
    #     {RFC 3339}[https://www.ietf.org/rfc/rfc3339.txt] format, nil if the key never expires
    #
    # @return [Hash<String, Any>] a {key object}[https://www.meilisearch.com/docs/reference/api/keys#key-object]
    def create_key(key_options)
      body = Utils.transform_attributes(key_options)

      http_post '/keys', body
    end

    # Update an existing API key.
    #
    # This and other key methods require that the Meilisearch instance have a
    # {master key}[https://www.meilisearch.com/docs/learn/security/differences_master_api_keys#master-key]
    # set.
    #
    # @see #create_key #create_key to create a new key
    # @see #keys #keys to get all keys in the instance
    # @see #key #key to fetch one key
    # @see https://www.meilisearch.com/docs/reference/api/keys#update-a-key Meilisearch API reference
    # @param key_options [Hash<Symbol, Any>] see {#create_key}
    #
    # @return [Hash<String, Any>] a {key object}[https://www.meilisearch.com/docs/reference/api/keys#key-object]
    def update_key(uid_or_key, key_options)
      body = Utils.transform_attributes(key_options)
      body = body.slice('description', 'name')

      http_patch "/keys/#{uid_or_key}", body
    end

    # Delete an API key.
    #
    #   # obviously this example uid will not correspond to a key on your server
    #   # please replace it with your own key's uid
    #   uid = '6062abda-a5aa-4414-ac91-ecd7944c0f8d'
    #   client.delete_key(uid)
    #
    # This and other key methods require that the Meilisearch instance have a
    # {master key}[https://www.meilisearch.com/docs/learn/security/differences_master_api_keys#master-key]
    # set.
    #
    # @see #keys #keys to get all keys in the instance
    # @see #create_key #create_key to create keys and set their scope
    # @see https://www.meilisearch.com/docs/reference/api/keys#delete-a-key Meilisearch API reference
    # @param uid_or_key [String] either the uuidv4 that is the key's
    #   {uid}[https://www.meilisearch.com/docs/reference/api/keys#uid] or
    #   a hash of the uid and the master key that is the key's
    #   {key}[https://www.meilisearch.com/docs/reference/api/keys#key] field
    def delete_key(uid_or_key)
      http_delete "/keys/#{uid_or_key}"
    end

    ### HEALTH

    # Check if Meilisearch instance is healthy.
    #
    # @see #health
    # @return [bool] whether or not the +/health+ endpoint raises any errors
    def healthy?
      http_get '/health'
      true
    rescue StandardError
      false
    end

    # Check health of Meilisearch instance.
    #
    # @see https://www.meilisearch.com/docs/reference/api/health#get-health Meilisearch API reference
    # @return [Hash<String, Any>] the health report from the Meilisearch instance
    def health
      http_get '/health'
    end

    ### STATS

    # Check version of Meilisearch server
    #
    # @see https://www.meilisearch.com/docs/reference/api/version#get-version-of-meilisearch Meilisearch API reference
    # @return [Hash<String, String>] package version and last commit of Meilisearch server, see
    #   {version object}[https://www.meilisearch.com/docs/reference/api/version#version-object]
    def version
      http_get '/version'
    end

    # Get stats of all indexes in instance.
    #
    # @see Index#stats
    # @see https://www.meilisearch.com/docs/reference/api/stats#get-stats-of-all-indexes Meilisearch API reference
    # @return [Hash<String, Any>] see {stats object}[https://www.meilisearch.com/docs/reference/api/stats#stats-object]
    def stats
      http_get '/stats'
    end

    ### DUMPS

    # Create a database dump.
    #
    # Dumps are "blueprints" which can be used to restore your database. Restoring
    # a dump requires reindexing all documents and is therefore inefficient.
    #
    # Dumps are created by the Meilisearch server in the directory where the server is started
    # under +dumps/+ by default.
    #
    # @see https://www.meilisearch.com/docs/learn/advanced/snapshots_vs_dumps
    #   The difference between snapshots and dumps
    # @see https://www.meilisearch.com/docs/learn/advanced/dumps
    #   Meilisearch documentation on how to use dumps
    # @see https://www.meilisearch.com/docs/reference/api/dump#create-a-dump
    #   Meilisearch API reference
    # @return [Models::Task] the async task that is creating the dump
    def create_dump
      response = http_post '/dumps'
      Models::Task.new(response, task_endpoint)
    end

    ### SNAPSHOTS

    # Create a database snapshot.
    #
    # Snapshots are exact copies of the Meilisearch database. As such they are pre-indexed
    # and restoring one is a very efficient operation.
    #
    # Snapshots are not compatible between Meilisearch versions. Snapshot creation takes priority
    # over other tasks.
    #
    # Snapshots are created by the Meilisearch server in the directory where the server is started
    # under +snapshots/+ by default.
    #
    # @see https://www.meilisearch.com/docs/learn/advanced/snapshots_vs_dumps
    #   The difference between snapshots and dumps
    # @see https://www.meilisearch.com/docs/learn/advanced/snapshots
    #   Meilisearch documentation on how to use snapshots
    # @see https://www.meilisearch.com/docs/reference/api/snapshots#create-a-snapshot
    #   Meilisearch API reference
    # @return [Models::Task] the async task that is creating the snapshot
    def create_snapshot
      http_post '/snapshots'
    end

    ### TASKS

    # Cancel tasks matching the filter.
    #
    # This route is meant to be used with options, please see the API reference.
    #
    # Operations in Meilisearch are done asynchronously using "tasks".
    # Tasks report their progress and status.
    #
    # Warning: This does not return instances of {Models::Task}. This is a raw
    # call to the Meilisearch API and the return is not modified.
    #
    # @see https://www.meilisearch.com/docs/reference/api/tasks#task-object The Task Object
    # @see https://www.meilisearch.com/docs/reference/api/tasks#cancel-tasks Meilisearch API reference
    # @param options [Hash<Symbol, Any>] task search options as snake cased symbols, see the API reference
    # @return [Hash<String, Any>] a Meilisearch task that is canceling other tasks
    def cancel_tasks(options = {})
      task_endpoint.cancel_tasks(options)
    end

    # Cancel tasks matching the filter.
    #
    # This route is meant to be used with options, please see the API reference.
    #
    # Operations in Meilisearch are done asynchronously using "tasks".
    # Tasks report their progress and status.
    #
    # Warning: This does not return instances of {Models::Task}. This is a raw
    # call to the Meilisearch API and the return is not modified.
    #
    # Tasks are run in batches, see {#batches}.
    #
    # @see https://www.meilisearch.com/docs/reference/api/tasks#task-object The Task Object
    # @see https://www.meilisearch.com/docs/reference/api/tasks#cancel-tasks Meilisearch API reference
    # @param options [Hash<Symbol, Any>] task search options as snake cased symbols, see the API reference
    # @return [Hash<String, Any>] a Meilisearch task that is canceling other tasks
    def delete_tasks(options = {})
      task_endpoint.delete_tasks(options)
    end

    # Get Meilisearch tasks matching the filters.
    #
    # Operations in Meilisearch are done asynchronously using "tasks".
    # Tasks report their progress and status.
    #
    # Warning: This does not return instances of {Models::Task}. This is a raw
    # call to the Meilisearch API and the return is not modified.
    #
    # @see https://www.meilisearch.com/docs/reference/api/tasks#task-object The Task Object
    # @see https://www.meilisearch.com/docs/reference/api/tasks#get-tasks Meilisearch API reference
    # @param options [Hash<Symbol, Any>] task search options as snake cased symbols, see the API reference
    # @return [Hash<String, Any>] results of the task search, see API reference
    def tasks(options = {})
      task_endpoint.task_list(options)
    end

    # Get one task.
    #
    # Operations in Meilisearch are done asynchronously using "tasks".
    # Tasks report their progress and status.
    #
    # Warning: This does not return instances of {Models::Task}. This is a raw
    # call to the Meilisearch API and the return is not modified.
    #
    # @see https://www.meilisearch.com/docs/reference/api/tasks#task-object The Task Object
    # @see https://www.meilisearch.com/docs/reference/api/tasks#get-one-task Meilisearch API reference
    # @param task_uid [String] uid of the requested task
    # @return [Hash<String, Any>] a Meilisearch task object (see above)
    def task(task_uid)
      task_endpoint.task(task_uid)
    end

    # Wait for a task in a busy loop.
    #
    # Try to avoid using it. Wrapper around {Task#wait_for_task}.
    # @see Task#wait_for_task
    def wait_for_task(task_uid, timeout_in_ms = 5000, interval_in_ms = 50)
      task_endpoint.wait_for_task(task_uid, timeout_in_ms, interval_in_ms)
    end

    ### BATCHES

    # Get Meilisearch task batches matching the filters.
    #
    # Operations in Meilisearch are done asynchronously using "tasks".
    # Tasks are run in batches.
    #
    # @see https://www.meilisearch.com/docs/reference/api/batches#batch-object The Batch Object
    # @see https://www.meilisearch.com/docs/reference/api/batches#get-batches Meilisearch API reference
    # @param options [Hash<Symbol, Any>] task search options as snake cased symbols, see the API reference
    # @return [Hash<String, Any>] results of the batches search, see API reference
    def batches(options = {})
      http_get '/batches', options
    end

    # Get a single Meilisearch task batch matching +batch_uid+.
    #
    # Operations in Meilisearch are done asynchronously using "tasks".
    # Tasks are run in batches.
    #
    # @see https://www.meilisearch.com/docs/reference/api/batches#batch-object The Batch Object
    # @see https://www.meilisearch.com/docs/reference/api/batches#get-one-batch Meilisearch API reference
    # @param batch_uid [String] the uid of the request batch
    # @return [Hash<String, Any>] a batch object, see above
    def batch(batch_uid)
      http_get "/batches/#{batch_uid}"
    end

    private

    def index_object(uid, primary_key = nil)
      Index.new(uid, @base_url, @api_key, primary_key, @options)
    end

    def task_endpoint
      @task_endpoint ||= Task.new(@base_url, @api_key, @options)
    end
  end
end
