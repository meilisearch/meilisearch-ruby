# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# meilisearchsearch.gemspec dependencies
gemspec

group :development, :test do
  gem 'byebug'
  gem 'rspec', '~> 3.0'
  gem 'simplecov'
  gem 'codecov'

  # Used only for testing, none of the classes are exposed to the public API.
  gem 'jwt'
end

group :development do
  gem 'rubocop', '~> 1.50.1', require: false
end
