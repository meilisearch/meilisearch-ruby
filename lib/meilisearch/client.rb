# frozen_string_literal: true

require 'meilisearch/http_request'
require 'meilisearch/client/keys'
require 'meilisearch/client/stats'
require 'meilisearch/client/health'
require 'meilisearch/client/indexes'
require 'meilisearch/client/prepare'

module MeiliSearch
  class Client < HTTPRequest

    include MeiliSearch::Client::Keys
    include MeiliSearch::Client::Stats
    include MeiliSearch::Client::Health
    include MeiliSearch::Client::Indexes
    include MeiliSearch::Client::Prepare

  end
end
