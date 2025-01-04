# frozen_string_literal: true

require 'json'

require 'meilisearch/version'
require 'meilisearch/utils'
require 'meilisearch/models/task'
require 'meilisearch/http_request'
require 'meilisearch/multi_search'
require 'meilisearch/tenant_token'
require 'meilisearch/task'
require 'meilisearch/client'
require 'meilisearch/index'

module Meilisearch
end

module MeiliSearch
  class << self
    # Softly deprecate the old spelling of the top level module
    # from MeiliSearch to Meilisearch
    def const_missing(const_name)
      return super if @warned && @constants_defined

      _warn_about_deprecation
      _define_constants

      # Now that all the proper constants have been set,
      # we can tell ruby to search for the const in MeiliSearch again.
      # If it's still not found, then it does not exist in
      # Meilisearch and the call to `super` will throw a normal error
      const_get(const_name)
    end

    def method_missing(method_name, *args, **kwargs)
      _warn_about_deprecation
      _define_constants

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

    def _define_constants
      return if @constants_defined

      Meilisearch.constants.each do |constant|
        const_set(constant, Meilisearch.const_get(constant))
      end

      @constants_defined = true
    end
  end
end
