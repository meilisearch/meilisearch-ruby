# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'lib', 'meilisearch', 'version')

Gem::Specification.new do |s|
  s.name        = 'meilisearch'
  s.version     = MeiliSearch::VERSION
  s.authors     = ['Meili']
  s.email       = 'bonjour@meilisearch.com'
  s.summary     = 'An easy-to-use ruby client for Meilisearch API'
  s.description = 'An easy-to-use ruby client for Meilisearch API. See https://github.com/meilisearch/MeiliSearch'
  s.homepage    = 'https://github.com/meilisearch/meilisearch-ruby'
  s.licenses    = ['MIT']
  s.date        = Time.now

  s.files       = [
    'lib/meilisearch.rb',
    'lib/meilisearch/error.rb',
    'lib/meilisearch/http_request.rb',
    'lib/meilisearch/client.rb',
    'lib/meilisearch/index.rb',
    'lib/meilisearch/version.rb'
  ]

  s.required_ruby_version = '>= 2.6.0'
  s.add_dependency 'httparty', '>= 0.17.1', '< 0.21.0'
end
