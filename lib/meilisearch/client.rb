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

    # def get_or_create_index(index_uid, options = {})
    #   begin
    #     index_instance = fetch_index(index_uid)
    #   rescue ApiError => e
    #     raise e unless e.code == 'index_not_found'

    #     index_instance = create_index(index_uid, options)
    #   end
    #   index_instance
    # end

    def delete_index(index_uid)
      index_object(index_uid).delete
    end

    # # Usage:
    # # client.delete_index_if_exists('indexUID')
    # def delete_index_if_exists(index_uid)
    #   index_object(index_uid).delete
    #   true
    # rescue ApiError => e
    #   raise e if e.code != 'index_not_found'

    #   false
    # end

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
      http_get '/tasks'
    end

    def task(task_uid)
      http_get "/tasks/#{task_uid}"
    end

    def wait_for_task(task_uid, timeout_in_ms = 5000, interval_in_ms = 50)
      Timeout.timeout(timeout_in_ms.to_f / 1000) do
        loop do
          task = task(task_uid) # TO CHANGE!!!
          return task if achieved_task?(task)

          sleep interval_in_ms.to_f / 1000
        end
      end
    rescue Timeout::Error
      raise MeiliSearch::TimeoutError
    end

    private

    def achieved_task?(task)
      task['status'] != 'enqueued' && task['status'] != 'processing'
    end

    def index_object(uid, primary_key = nil)
      Index.new(uid, @base_url, @api_key, primary_key, @options)
    end
  end
end
