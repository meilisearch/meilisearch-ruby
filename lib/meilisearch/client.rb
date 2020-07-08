# frozen_string_literal: true

require 'meilisearch/http_request'

module MeiliSearch
  class Client < HTTPRequest
    ### INDEXES

    def indexes
      http_get '/indexes'
    end

    def show_index(index_uid)
      index_object(index_uid).show
    end

    # Usage:
    # client.create_index('indexUID')
    # client.create_index('indexUID', primaryKey: 'id')
    def create_index(index_uid, options = {})
      body = options.merge(uid: index_uid)
      res = http_post '/indexes', body
      index_object(res['uid'])
    end

    def get_or_create_index(index_uid, options = {})
      begin
        create_index(index_uid, options)
      rescue ApiError => e
        raise e unless e.code == 'index_already_exists'
      end
      index_object(index_uid)
    end

    def delete_index(index_uid)
      index_object(index_uid).delete
    end

    # Usage:
    # client.index('indexUID')
    def index(index_uid)
      index_object(index_uid)
    end
    alias get_index index

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

    def update_health(bool)
      http_put '/health', health: bool
    end

    ### STATS

    def version
      http_get '/version'
    end

    def sysinfo
      http_get '/sys-info'
    end

    def pretty_sysinfo
      http_get '/sys-info/pretty'
    end

    def stats
      http_get '/stats'
    end

    private

    def index_object(uid)
      Index.new(uid, @base_url, @api_key)
    end
  end
end
