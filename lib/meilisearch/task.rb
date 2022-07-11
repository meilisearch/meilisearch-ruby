# frozen_string_literal: true

require 'meilisearch/http_request'
require 'timeout'

module MeiliSearch
  class Task < HTTPRequest
    ALLOWED_PARAMS = [:limit, :from, :index_uid, :type, :status].freeze

    def task_list(options = {})
      body = Utils.transform_attributes(options.transform_keys(&:to_sym).slice(*ALLOWED_PARAMS))
      body = body.transform_values { |v| v.respond_to?(:join) ? v.join(',') : v }

      http_get '/tasks/', body
    end

    def task(task_uid)
      http_get "/tasks/#{task_uid}"
    end

    def index_tasks(index_uid)
      http_get '/tasks', { indexUid: [index_uid].flatten.join(',') }
    end

    def index_task(task_uid)
      http_get "/tasks/#{task_uid}"
    end

    def wait_for_task(task_uid, timeout_in_ms = 5000, interval_in_ms = 50)
      Timeout.timeout(timeout_in_ms.to_f / 1000) do
        loop do
          task = task(task_uid)
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
  end
end
