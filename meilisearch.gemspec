# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'lib', 'meilisearch', 'version')

Gem::Specification.new do |s|
  s.name        = 'meilisearch'
  s.version     = MeiliSearch::VERSION
  s.authors     = ['Meili']
  s.email       = 'bonjour@meilisearch.com'
  s.summary     = 'An easy-to-use ruby client for Meilisearch API'
  s.description = 'An easy-to-use ruby client for Meilisearch API. See https://github.com/meilisearch/meilisearch'
  s.homepage    = 'https://github.com/meilisearch/meilisearch-ruby'
  s.licenses    = ['MIT']

  s.files       = Dir['{lib}/**/*', 'LICENSE', 'README.md']

  s.required_ruby_version = '>= 3.0.0'
  s.add_dependency 'httparty', '>= 0.17.1', '< 0.23.0'
  s.metadata['rubygems_mfa_required'] = 'true'
end
