# frozen_string_literal: true

module Meilisearch
  class Client < HTTPRequest
    include Meilisearch::TenantToken
    include Meilisearch::MultiSearch

    ### INDEXES

    def raw_indexes(options = {})
      body = Utils.transform_attributes(options.transform_keys(&:to_sym).slice(:limit, :offset))

      http_get('/indexes', body)
    end

    def swap_indexes(*options)
      mapped_array = options.map { |arr| { indexes: arr } }

      response = http_post '/swap-indexes', mapped_array
      Models::Task.new(response, task_endpoint)
    end

    def indexes(options = {})
      response = raw_indexes(options)

      response['results'].map! do |index_hash|
        index_object(index_hash['uid'], index_hash['primaryKey'])
      end

      response
    end

    # Usage:
    # client.create_index('indexUID')
    # client.create_index('indexUID', primary_key: 'id')
    def create_index(index_uid, options = {})
      body = Utils.transform_attributes(options.merge(uid: index_uid))

      response = http_post '/indexes', body

      Models::Task.new(response, task_endpoint)
    end

    # Synchronous version of create_index.
    # Waits for the task to be achieved, be careful when using it.
    def create_index!(index_uid, options = {})
      Utils.soft_deprecate(
        'Client#create_index!',
        "client.create_index('#{index_uid}').await"
      )

      create_index(index_uid, options).await
    end

    def delete_index(index_uid)
      index_object(index_uid).delete
    end

    # Usage:
    # client.index('indexUID')
    def index(index_uid)
      index_object(index_uid)
    end

    def fetch_index(index_uid)
      index_object(index_uid).fetch_info
    end

    def fetch_raw_index(index_uid)
      index_object(index_uid).fetch_raw_info
    end

    ### KEYS

    def keys(limit: nil, offset: nil)
      body = { limit: limit, offset: offset }.compact

      http_get '/keys', body
    end

    def key(uid_or_key)
      http_get "/keys/#{uid_or_key}"
    end

    def create_key(key_options)
      body = Utils.transform_attributes(key_options)

      http_post '/keys', body
    end

    def update_key(uid_or_key, key_options)
      body = Utils.transform_attributes(key_options)
      body = body.slice('description', 'name')

      http_patch "/keys/#{uid_or_key}", body
    end

    def delete_key(uid_or_key)
      http_delete "/keys/#{uid_or_key}"
    end

    ### HEALTH

    def healthy?
      http_get '/health'
      true
    rescue StandardError
      false
    end

    def health
      http_get '/health'
    end

    ### STATS

    def version
      http_get '/version'
    end

    def stats
      http_get '/stats'
    end

    ### DUMPS

    def create_dump
      response = http_post '/dumps'
      Models::Task.new(response, task_endpoint)
    end

    ### SNAPSHOTS

    def create_snapshot
      http_post '/snapshots'
    end

    ### TASKS

    def cancel_tasks(options = {})
      task_endpoint.cancel_tasks(options)
    end

    def delete_tasks(options = {})
      task_endpoint.delete_tasks(options)
    end

    def tasks(options = {})
      task_endpoint.task_list(options)
    end

    def task(task_uid)
      task_endpoint.task(task_uid)
    end

    def wait_for_task(task_uid, timeout_in_ms = 5000, interval_in_ms = 50)
      task_endpoint.wait_for_task(task_uid, timeout_in_ms, interval_in_ms)
    end

    ### BATCHES

    def batches(options = {})
      http_get '/batches', options
    end

    def batch(batch_uid)
      http_get "/batches/#{batch_uid}"
    end

    ### EXPERIMENTAL FEATURES

    def experimental_features
      http_get '/experimental-features'
    end

    def update_experimental_features(expe_feat_changes)
      expe_feat_changes = Utils.transform_attributes(expe_feat_changes)
      http_patch '/experimental-features', expe_feat_changes
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
