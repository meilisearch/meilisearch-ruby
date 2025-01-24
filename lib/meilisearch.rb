# frozen_string_literal: true

require 'json'

require 'meilisearch/version'
require 'meilisearch/utils'
require 'meilisearch/models/task'
require 'meilisearch/http_request'
require 'meilisearch/multi_search'
require 'meilisearch/network'
require 'meilisearch/tenant_token'
require 'meilisearch/task'
require 'meilisearch/client'
require 'meilisearch/index'

module Meilisearch
end

# Softly deprecate the old spelling of the top level module
# from MeiliSearch to Meilisearch
module MeiliSearch
  class << self
    def const_missing(const_name)
      _warn_about_deprecation

      Meilisearch.const_get(const_name)
    end

    def method_missing(method_name, *args, **kwargs)
      _warn_about_deprecation

      Meilisearch.send(method_name, *args, **kwargs)
    end

    def respond_to_missing?(method_name, *)
      Meilisearch.respond_to?(method_name) || super
    end

    private

    def _warn_about_deprecation
      return if @warned

      Meilisearch::Utils.logger.warn <<~RENAMED_MODULE_WARNING
        [meilisearch-ruby] The top-level module of Meilisearch has been renamed.
        [meilisearch-ruby] Please update "MeiliSearch" to "Meilisearch".
      RENAMED_MODULE_WARNING

      @warned = true
    end
  end
end
