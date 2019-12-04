# frozen_string_literal: true

require 'meilisearch/http_request'
require 'meilisearch/index/base'
require 'meilisearch/index/documents'
require 'meilisearch/index/search'
require 'meilisearch/index/stats'

module MeiliSearch
  class Index < HTTPRequest

    include MeiliSearch::Index::Base
    include MeiliSearch::Index::Documents
    include MeiliSearch::Index::Search
    include MeiliSearch::Index::Stats

    attr_reader :uid

    def initialize(index_uid, url, api_key = nil)
      @uid = index_uid
      super(url, api_key)
    end

    def name
      get_index_name_from_uid
    end
    alias_method :get_name, :name

    private

    def get_index_name_from_uid
      index = show
      if index.nil?
        raise IndexIdentifierError
      else
        index['name']
      end
    end

  end
end
