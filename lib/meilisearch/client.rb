# frozen_string_literal: true

require 'meilisearch/http_request'

module MeiliSearch
  class Client < HTTPRequest
    ### INDEXES

    def raw_indexes
      http_get('/indexes')
    end

    def indexes
      raw_indexes.map do |index_hash|
        index_object(index_hash['uid'], index_hash['primaryKey'])
      end
    end

    # Usage:
    # client.create_index('indexUID')
    # client.create_index('indexUID', primaryKey: 'id')
    def create_index(index_uid, options = {})
      body = Utils.transform_attributes(options.merge(uid: index_uid))

      http_post '/indexes', body
    end

    # Synchronous version of create_index.
    # Waits for the task to be achieved, be careful when using it.
    def create_index!(index_uid, options = {})
      task = create_index(index_uid, options)
      wait_for_task(task['uid'])
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

    def keys
      http_get '/keys'
    end
    alias get_keys keys

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
      http_post '/dumps'
    end

    def dump_status(dump_uid)
      http_get "/dumps/#{dump_uid}/status"
    end
    alias get_dump_status dump_status

    ### TASKS

    def tasks
      task_endpoint.global_tasks
    end

    def task(task_uid)
      task_endpoint.global_task(task_uid)
    end

    def wait_for_task(task_uid, timeout_in_ms = 5000, interval_in_ms = 50)
      task_endpoint.wait_for_task(task_uid, timeout_in_ms, interval_in_ms)
    end

    private

    def index_object(uid, primary_key = nil)
      Index.new(uid, @base_url, @api_key, primary_key, @options)
    end

    def task_endpoint
      Task.new(@base_url, @api_key, @options)
    end
  end
end
