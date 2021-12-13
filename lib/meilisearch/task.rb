# frozen_string_literal: true

require 'meilisearch/http_request'
require 'timeout'

module MeiliSearch
  class Task < HTTPRequest
    def global_tasks
      http_get '/tasks/'
    end

    def global_task(task_uid)
      http_get "/tasks/#{task_uid}"
    end

    def index_tasks(index_uid)
      http_get "/indexes/#{index_uid}/tasks"
    end

    def index_task(index_uid, task_uid)
      http_get "/indexes/#{index_uid}/tasks/#{task_uid}"
    end

    def wait_for_task(task_uid, timeout_in_ms = 5000, interval_in_ms = 50)
      Timeout.timeout(timeout_in_ms.to_f / 1000) do
        loop do
          task = global_task(task_uid)
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
