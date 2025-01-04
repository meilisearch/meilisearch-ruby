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
  # Softly deprecate the old spelling of the top level module
  # from MeiliSearch to Meilisearch
  def self.const_missing(const_name)
    return super if @warned

    Meilisearch::Utils.logger.warn <<~RENAMED_MODULE_WARNING
      [meilisearch-ruby] The top-level module of Meilisearch has been renamed.
      [meilisearch-ruby] Please update "MeiliSearch" to "Meilisearch".
    RENAMED_MODULE_WARNING

    Meilisearch.constants.each do |constant|
      const_set(constant, Meilisearch.const_get(constant))
    end

    @warned = true

    # Now that all the proper constants have been set,
    # we can tell ruby to search for the const in MeiliSearch again.
    # If it's still not found, then it does not exist in
    # Meilisearch and the call to `super` will throw a normal error
    const_get(const_name)
  end

  def self.method_missing(method_name)
    unless @warned
      Meilisearch::Utils.logger.warn <<~RENAMED_MODULE_WARNING
        [meilisearch-ruby] The top-level module of Meilisearch has been renamed.
        [meilisearch-ruby] Please update "MeiliSearch" to "Meilisearch".
      RENAMED_MODULE_WARNING

      Meilisearch.constants.each do |constant|
        const_set(constant, Meilisearch.const_get(constant))
      end
    end

    @warned = true

    Meilisearch.send(method_name)
  end
end
