# MeiliSearch Ruby Client <!-- omit in toc -->

[![Gem Version](https://badge.fury.io/rb/meilisearch.svg)](https://badge.fury.io/rb/meilisearch)
[![Licence](https://img.shields.io/badge/licence-MIT-blue.svg)](https://img.shields.io/badge/licence-MIT-blue.svg)
[![Actions Status](https://github.com/meilisearch/meilisearch-ruby/workflows/Test/badge.svg)](https://github.com/meilisearch/meilisearch-ruby/actions)

The ruby client for MeiliSearch API.

MeiliSearch provides an ultra relevant and instant full-text search. Our solution is open-source and you can check out [our repository here](https://github.com/meilisearch/MeiliDB).</br>

Here is the [MeiliSearch documentation](https://docs.meilisearch.com/) 📖

## Table of Contents <!-- omit in toc -->

- [🔧 Installation](#-installation)
- [🚀 Getting started](#-getting-started)
- [🎬 Examples](#-examples)
  - [Indexes](#indexes)
  - [Documents](#documents)
  - [Update status](#update-status)
  - [Search](#search)
- [🤖 Compatibility with MeiliSearch](#-compatibility-with-meilisearch)

## 🔧 Installation

With `gem` in command line:
```bash
$ gem install meilisearch
```

In your `Gemfile` with [bundler](https://bundler.io/):
```ruby
source 'https://rubygems.org'

gem 'meilisearch'
```

### Run MeiliSearch <!-- omit in toc -->

There are many ways to run a MeiliSearch instance.
All of them are detailed in the [documentation](https://docs.meilisearch.com/advanced_guides/binary.html).

For example, if you use Docker:
```bash
$ docker run -it --rm -p 7700:7700 getmeili/meilisearch:latest --api-key=apiKey
```

## 🚀 Getting started

#### Add documents <!-- omit in toc -->

```ruby
require 'meilisearch'

client = MeiliSearch::Client.new('url', 'apiKey')
index = client.create_index(name: 'Books', uid: 'books') # If your index does not exist
index = client.index('books')                            # If you already created your index

documents = [
  { id: 123,  title: 'Pride and Prejudice' },
  { id: 456,  title: 'Le Petit Prince' },
  { id: 1,    title: 'Alice In Wonderland' },
  { id: 1344, title: 'The Hobbit' },
  { id: 4,    title: 'Harry Potter and the Half-Blood Prince' },
  { id: 42,   title: 'The Hitchhiker\'s Guide to the Galaxy' }
]
index.add_documents(documents) # => { "updateId": 1 }
```

With the `updateId`, you can check the status of your documents addition thanks to this [method](https://github.com/meilisearch/meilisearch-ruby#update-status).

#### Search in index <!-- omit in toc -->
``` ruby
# MeiliSearch is typo-tolerant:
puts index.search('hary pottre')
```
Output:
```ruby
{
  "hits" => [{
    "id" => 4,
    "title" => "Harry Potter and the Half-Blood Prince"
  }],
  "offset" => 0,
  "limit" => 20,
  "processingTimeMs" => 1,
  "query" => "hary pottre"
}
```

## 🎬 Examples

All HTTP routes of MeiliSearch are accessible via methods in this SDK.</br>
You can check out [the API documentation](https://docs.meilisearch.com/references/).

### Indexes

#### Create an index <!-- omit in toc -->
```ruby
# Create an index
client.create_index('Books')
# Create an index with a specific uid (uid must be unique)
client.create_index(name: 'Books', uid: 'books')
# Create an index with a schema
schema = {
  id:    [:displayed, :indexed, :identifier],
  title: [:displayed, :indexed]
}
client.create_index(name: 'Books', schema: schema)
```

#### List all indexes <!-- omit in toc -->
```ruby
client.indexes
```

#### Get an index object <!-- omit in toc -->
```ruby
client.index('indexUid')
```

### Documents

#### Fetch documents <!-- omit in toc -->
```ruby
# Get one document
index.document(123)
# Get documents by batch
index.documents(offset: 10 , limit: 20)
```
#### Add documents <!-- omit in toc -->
```ruby
index.add_documents({ id: 2, title: 'Madame Bovary' })
```

Response:
```json
{
    "updateId": 1
}
```
With this `updateId` you can track your [operation update](#update-status).

#### Delete documents <!-- omit in toc -->
```ruby
# Delete one document
index.delete_document(2)
# Delete several documents
index.delete_documents([1, 42])
# Delete all documents /!\
index.clear_documents
```

### Update status
```ruby
# Get one update status
# Parameter: the updateId got after an asynchronous request (e.g. documents addition)
index.get_update_status(1)
# Get all update satus
index.get_all_update_status
```

### Search

#### Basic search <!-- omit in toc -->

```ruby
index.search('prince')
```

```json
{
    "hits": [
        {
            "id": 456,
            "title": "Le Petit Prince"
        },
        {
            "id": 4,
            "title": "Harry Potter and the Half-Blood Prince"
        }
    ],
    "offset": 0,
    "limit": 20,
    "processingTimeMs": 13,
    "query": "prince"
}
```

#### Custom search <!-- omit in toc -->

All the supported options are described in [this documentation section](https://docs.meilisearch.com/references/search.html#search-in-an-index).

```ruby
index.search('prince', { limit: 1 })
```

```json
{
    "hits": [
        {
            "id": 456,
            "title": "Le Petit Prince"
        }
    ],
    "offset": 0,
    "limit": 1,
    "processingTimeMs": 10,
    "query": "prince"
}
```

## 🤖 Compatibility with MeiliSearch

This gem works for MeiliSearch `v0.8.x`.
