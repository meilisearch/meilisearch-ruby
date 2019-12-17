# frozen_string_literal: true

require 'meilisearch/http_request'
require 'meilisearch/index/base'
require 'meilisearch/index/documents'
require 'meilisearch/index/search'
require 'meilisearch/index/stats'
require 'meilisearch/index/settings'
require 'meilisearch/index/updates'
require 'meilisearch/index/stop_words'
require 'meilisearch/index/synonyms'

module MeiliSearch
  class Index < HTTPRequest
    include MeiliSearch::Index::Base
    include MeiliSearch::Index::Documents
    include MeiliSearch::Index::Search
    include MeiliSearch::Index::Stats
    include MeiliSearch::Index::Settings
    include MeiliSearch::Index::Updates
    include MeiliSearch::Index::StopWords
    include MeiliSearch::Index::Synonyms

    attr_reader :uid

    def initialize(index_uid, url, api_key = nil)
      @uid = index_uid
      super(url, api_key)
    end

    def name
      index_name_from_uid
    end
    alias get_name name

    private

    def index_name_from_uid
      show['name']
    end
  end
end
