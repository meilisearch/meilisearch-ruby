# frozen_string_literal: true

# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration

# NOTE: If SimpleCov starts after your application code is already loaded (via require),
# it won't be able to track your files and their coverage!
# The SimpleCov.start must be issued before any of your application code is required!

unless ENV.fetch('DISABLE_COVERAGE', false)
  require 'simplecov'

  SimpleCov.start do
    add_filter %r{^/spec/}
    minimum_coverage 99

    if ENV['CI']
      require 'simplecov-cobertura'

      formatter SimpleCov::Formatter::CoberturaFormatter
    end
  end
end

require 'meilisearch'
require 'byebug'
require 'time'

# Globals for all tests
URL = format('http://%<host>s:%<port>s',
             host: ENV.fetch('MEILISEARCH_URL', 'localhost'), port: ENV.fetch('MEILISEARCH_PORT', '7700'))
MASTER_KEY = 'masterKey'
DEFAULT_SEARCH_RESPONSE_KEYS = [
  'hits',
  'offset',
  'limit',
  'estimatedTotalHits',
  'processingTimeMs',
  'query',
  'nbHits'
].freeze

FINITE_PAGINATED_SEARCH_RESPONSE_KEYS = [
  'hits',
  'query',
  'processingTimeMs',
  'hitsPerPage',
  'page',
  'totalPages',
  'totalHits'
].freeze

Dir["#{Dir.pwd}/spec/support/**/*.rb"].each { |file| require file }

RSpec.configure do |config|
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.order = :random

  config.include_context 'test defaults'

  config.include IndexesHelpers
  config.include ExceptionsHelpers
  config.include KeysHelpers

  # New RSpec 4 defaults, remove when updated to RSpec 4
  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
