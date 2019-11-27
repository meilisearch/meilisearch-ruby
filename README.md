# Meilisearch Ruby Client

[![Gem Version](https://badge.fury.io/rb/meilisearch.svg)](https://badge.fury.io/rb/meilisearch)
[![Licence](https://img.shields.io/badge/licence-MIT-blue.svg)](https://img.shields.io/badge/licence-MIT-blue.svg)

The ruby client for MeiliSearch API.

MeiliSearch provides an ultra relevant and instant full-text search. Our solution is open-source and you can check out [our repository here](https://github.com/meilisearch/MeiliDB).</br>
You can also use MeiliSearch as a service by registering on [meilisearch.com](https://www.meilisearch.com/) and use our hosted solution.


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

Here is a quickstart to create an index and add documents.

```ruby
require 'meilisearch'

client = MeiliSearch::Client.new('myUrl', 'myApiKey')
index = client.index('myIndexUid')

documents = [
  { id: 123,  title: 'Pride and Prejudice' },
  { id: 456,  title: 'Le Petit Prince' },
  { id: 1,    title: 'Alice In Wonderland' },
  { id: 1344, title: 'The Hobbit' },
  { id: 4,    title: 'Harry Potter and the Half-Blood Prince' },
  { id: 42,   title: 'The Hitchhiker\'s Guide to the Galaxy' }
]
index.add_documents(documents)
index.add_synonyms(['harry potter', 'hp'])
index.search('hp')
```

If you don't have any index yet, you can create one with:

```ruby
index = client.create_index('Books')
puts index.uid
```

## 🎬 Examples

You can check out [the API documentation](https://docs.meilisearch.com/references/).

### Search

#### Basic search

```ruby
response = client.index(index_uid).search('prince')
puts response
```

```json
{
    "hits": [
        {
            "id": 456,
            "title": "Le Petit Prince",
            "_formatted": {
                "id": 456,
                "title": "Le Petit Prince"
            }
        },
        {
            "id": 4,
            "title": "Harry Potter and the Half-Blood Prince",
            "_formatted": {
                "id": 4,
                "title": "Harry Potter and the Half-Blood Prince"
            }
        }
    ],
    "offset": 0,
    "limit": 20,
    "processingTimeMs": 13,
    "query": "prince"
}
```

#### Custom search

All the supported options are described in [this documentation section](https://docs.meilisearch.com/references/search.html#search-in-an-index).

```ruby
response = client.index(index_uid).search('prince', { limit: 1 })
puts response
```

```json
{
    "hits": [
        {
            "id": 456,
            "title": "Le Petit Prince",
            "_formatted": {
                "id": 456,
                "title": "Le Petit Prince"
            }
        }
    ],
    "offset": 0,
    "limit": 1,
    "processingTimeMs": 10,
    "query": "prince"
}
```
