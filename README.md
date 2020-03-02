# MeiliSearch Ruby Client <!-- omit in toc -->

[![Gem Version](https://badge.fury.io/rb/meilisearch.svg)](https://badge.fury.io/rb/meilisearch)
[![Licence](https://img.shields.io/badge/licence-MIT-blue.svg)](https://img.shields.io/badge/licence-MIT-blue.svg)
[![Actions Status](https://github.com/meilisearch/meilisearch-ruby/workflows/Test/badge.svg)](https://github.com/meilisearch/meilisearch-ruby/actions)

The ruby client for MeiliSearch API.

MeiliSearch provides an ultra relevant and instant full-text search. Our solution is open-source and you can check out [our repository here](https://github.com/meilisearch/MeiliSearch).

Here is the [MeiliSearch documentation](https://docs.meilisearch.com/) 📖

## Table of Contents <!-- omit in toc -->

- [🔧 Installation](#-installation)
- [🚀 Getting started](#-getting-started)
- [🎬 Examples](#-examples)
  - [Indexes](#indexes)
  - [Documents](#documents)
  - [Update status](#update-status)
  - [Search](#search)
- [⚙️ Development Workflow](#️-development-workflow)
  - [Install dependencies](#install-dependencies)
  - [Tests and Linter](#tests-and-linter)
  - [Release](#release)
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

There are many easy ways to [download and run a MeiliSearch instance](https://docs.meilisearch.com/guides/advanced_guides/installation.html#download-and-launch).

For example, if you use Docker:
```bash
$ docker run -it --rm -p 7700:7700 getmeili/meilisearch:latest --master-key=masterKey
```

NB: you can also download MeiliSearch from **Homebrew** or **APT**.

## 🚀 Getting started

#### Add documents <!-- omit in toc -->

```ruby
require 'meilisearch'

client = MeiliSearch::Client.new('http://127.0.0.1:7700/', 'masterKey')
index = client.create_index('books') # If your index does not exist
index = client.index('books')        # If you already created your index

documents = [
  { book_id: 123,  title: 'Pride and Prejudice' },
  { book_id: 456,  title: 'Le Petit Prince' },
  { book_id: 1,    title: 'Alice In Wonderland' },
  { book_id: 1344, title: 'The Hobbit' },
  { book_id: 4,    title: 'Harry Potter and the Half-Blood Prince' },
  { book_id: 42,   title: 'The Hitchhiker\'s Guide to the Galaxy' }
]
index.add_documents(documents) # => { "updateId": 0 }
```

With the `updateId`, you can check the status (`processed` of `failed`) of your documents addition thanks to this [method](#update-status).

#### Search in index <!-- omit in toc -->

``` ruby
# MeiliSearch is typo-tolerant:
puts index.search('harry pottre')
```
Output:
```ruby
{
  "hits" => [{
    "book_id" => 4,
    "title" => "Harry Potter and the Half-Blood Prince"
  }],
  "offset" => 0,
  "limit" => 20,
  "processingTimeMs" => 1,
  "query" => "harry pottre"
}
```

## 🎬 Examples

All HTTP routes of MeiliSearch are accessible via methods in this SDK.</br>
You can check out [the API documentation](https://docs.meilisearch.com/references/).

### Indexes

#### Create an index <!-- omit in toc -->

```ruby
# Create an index
client.create_index('books')
# Create an index and give the primary-key
client.create_index(uid: 'books', primaryKey: 'book_id')
```

#### List all indexes <!-- omit in toc -->

```ruby
client.indexes
```

#### Get an index object <!-- omit in toc -->

```ruby
client.index('books')
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
index.add_documents({ book_id: 2, title: 'Madame Bovary' })
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
index.delete_all_documents
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
            "book_id": 456,
            "title": "Le Petit Prince"
        },
        {
            "book_id": 4,
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
index.search('prince', { limit: 1, attributesToHighlight: '*' })
```

```json
{
    "hits": [
        {
            "title": "Le Petit Prince",
            "_formatted": {
                "title": "Le Petit <em>Prince</em>"
            }
        }
    ],
    "offset": 0,
    "limit": 1,
    "processingTimeMs": 0,
    "query": "prince"
}
```

## ⚙️ Development Workflow

If you want to contribute, this sections describes the steps to follow.

Thank you for your interest in a MeiliSearch tool! ♥️

### Install dependencies

```bash
$ bundle install
```

### Tests and Linter

Each PR should pass the tests and the linter to be accepted.

```bash
# Tests
$ docker run -d -p 7700:7700 getmeili/meilisearch:latest ./meilisearch --master-key=masterKey --no-analytics
$ bundle exec rspec
# Linter
$ bundle exec rubocop lib/ spec/
# Linter with auto-correct
$ bundle exec rubocop -a lib/ spec/
```

### Release

MeiliSearch tools follow the [Semantic Versioning Convention](https://semver.org/).

You must do a PR modifying the file `lib/meilisearch/version.rb` with the right version.<br>

```ruby
VERSION = 'X.X.X'
```

Once the changes are merged on `master`, in your terminal, you must be on the `master` branch and push a new tag with the right version:

```bash
$ git checkout master
$ git pull origin master
$ git tag vX.X.X
$ git push --tag origin master
```

A GitHub Action will be triggered and push the new gem on [RubyGems](https://rubygems.org/gems/meilisearch).

## 🤖 Compatibility with MeiliSearch

This gem works for MeiliSearch `v0.9.x`.
