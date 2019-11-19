# ruby-meili-api

[![Gem Version](https://badge.fury.io/rb/meilisearch.svg)](https://badge.fury.io/rb/meilisearch)
[![Licence](https://img.shields.io/badge/licence-MIT-blue.svg)](https://img.shields.io/badge/licence-MIT-blue.svg)

The ruby client for the MeiliSearch API.

MeiliSearch provides an ultra relevant and instant full-text search. Our solution is open-source and you can check out [our repository here](https://github.com/meilisearch/MeiliDB).</br>
Also, you can use MeiliSearch as a service by registering to [meilisearch.com](https://www.meilisearch.com/) and use our cloud solution.

## 🔧 Installation

With `gem` in command line:
```bash
$> gem install meilisearch
```

In your `Gemfile` with [bundler](https://bundler.io/):
```ruby
source 'https://rubygems.org'

gem 'meilisearch'
```

## 🚀 Getting started

Here is a quickstart for a request index creation.

```ruby
require 'meilisearch'

client = MeiliSearch::Client.new(
  'yourUrl',
  'yourApiKey'
)
response = client.create_index('yourIndexUid')
puts response.status
puts response.body
```

## Examples

