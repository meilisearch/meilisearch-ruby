---
name: Bug Report 🐞
about: Create a report to help us improve.
title: ''
labels: ["bug"]
assignees: ''
---

<!-- This is not an exhaustive model but a help. No step is mandatory. -->

### Description
<!-- Description of what the bug is about. -->

### Expected behavior
<!-- What you expected to happen. -->

### Current behavior
<!-- What happened. -->

### Screenshots or logs
<!-- If applicable, add screenshots or logs to help explain your problem. -->

### Environment
**Operating System** [e.g. Debian GNU/Linux] (`cat /etc/*-release | head -n1`):

**Meilisearch version** (`./meilisearch --version`):

**meilisearch-ruby version** (`bundle info meilisearch` or `gem list meilisearch$`):

### Reproduction script:

<!-- Write a script that reproduces your issue. Feel free to get started with the example below -->

<!--
```ruby
require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"
  gem 'minitest', '~> 5.25', '>= 5.25.4'

  gem 'meilisearch', ENV["MEILISEARCH_RUBY_VERSION"] || "~> 0.31.0"
  # If you want to test against changes that have been not released yet
  # gem "meilisearch", github: "meilisearch/meilisearch-ruby", branch: "main"

  # Open a debugging session with the `debugger` method
  # gem 'debug'
end

require 'minitest/autorun'

URL = format('http://%<host>s:%<port>s',
             host: ENV.fetch('MEILISEARCH_URL', 'localhost'), port: ENV.fetch('MEILISEARCH_PORT', '7700'))

$client = Meilisearch::Client.new(URL, 'masterKey', { timeout: 2, max_retries: 1 })

class BugTest < Minitest::Test
  def test_my_bug
    # your code here
  end
end
```
-->
