# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'lib', 'meilisearch', 'version')

Gem::Specification.new do |s|
  s.name        = 'meilisearch'
  s.version     = MeiliSearch::VERSION
  s.authors     = ['Meili']
  s.email       = 'bonjour@meilisearch.com'
  s.summary     = 'A simple ruby client for Meilisearch API'
  s.description = 'A simple ruby client for Meilisearch API. See https://github.com/meilisearch/MeiliDB'
  s.homepage    = 'https://github.com/meilisearch/ruby-meili-api'
  s.licenses    = ['MIT']
  s.date        = Time.now

  s.files       = [
    'lib/meilisearch.rb',
    'lib/meilisearch/error.rb',
    'lib/meilisearch/http_request.rb',
    'lib/meilisearch/client.rb',
    'lib/meilisearch/index.rb',
    'lib/meilisearch/version.rb',
    'lib/meilisearch/client/health.rb',
    'lib/meilisearch/client/stats.rb',
    'lib/meilisearch/client/keys.rb',
    'lib/meilisearch/client/prepare.rb',
    'lib/meilisearch/client/indexes.rb',
    'lib/meilisearch/index/base.rb',
    'lib/meilisearch/index/search.rb',
    'lib/meilisearch/index/documents.rb',
    'lib/meilisearch/index/stats.rb'
  ]

  s.add_dependency 'httparty', '~> 0.17.1'
end
