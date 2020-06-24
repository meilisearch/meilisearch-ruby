<p align="center">
  <img src="https://res.cloudinary.com/meilisearch/image/upload/v1587402338/SDKs/meilisearch_ruby.svg" alt="MeiliSearch-Ruby" width="200" height="200" />
</p>

<h1 align="center">MeiliSearch Ruby</h1>

<h4 align="center">
  <a href="https://github.com/meilisearch/MeiliSearch">MeiliSearch</a> |
  <a href="https://www.meilisearch.com">Website</a> |
  <a href="https://blog.meilisearch.com">Blog</a> |
  <a href="https://twitter.com/meilisearch">Twitter</a> |
  <a href="https://docs.meilisearch.com">Documentation</a> |
  <a href="https://docs.meilisearch.com/faq">FAQ</a>
</h4>

<p align="center">
  <a href="https://badge.fury.io/rb/meilisearch"><img src="https://badge.fury.io/rb/meilisearch.svg" alt="Latest Stable Version"></a>
  <a href="https://github.com/meilisearch/meilisearch-ruby/actions"><img src="https://github.com/meilisearch/meilisearch-ruby/workflows/Test/badge.svg" alt="Test"></a>
  <a href="https://github.com/meilisearch/meilisearch-ruby/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-informational" alt="License"></a>
  <a href="https://slack.meilisearch.com"><img src="https://img.shields.io/badge/slack-MeiliSearch-blue.svg?logo=slack" alt="Slack"></a>
</p>

<p align="center">⚡ Lightning Fast, Ultra Relevant, and Typo-Tolerant Search Engine MeiliSearch client written in Ruby 💎</p>

**MeiliSearch Ruby** is a client for **MeiliSearch** written in Ruby. **MeiliSearch** is a powerful, fast, open-source, easy to use and deploy search engine. Both searching and indexing are highly customizable. Features such as typo-tolerance, filters, and synonyms are provided out-of-the-box.

## Table of Contents <!-- omit in toc -->

- [🔧 Installation](#-installation)
- [🚀 Getting started](#-getting-started)
- [🤖 Compatibility with MeiliSearch](#-compatibility-with-meilisearch)
- [🎬 Examples](#-examples)
  - [Indexes](#indexes)
  - [Documents](#documents)
  - [Update status](#update-status)
  - [Search](#search)
- [⚙️ Development Workflow](#️-development-workflow)
  - [Install dependencies](#install-dependencies)
  - [Tests](#tests)
  - [Linter](#linter)
  - [Want to debug?](#want-to-debug)
  - [Release](#release)

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
$ docker run -it --rm -p 7700:7700 getmeili/meilisearch:latest ./meilisearch --master-key=masterKey
```

NB: you can also download MeiliSearch from **Homebrew** or **APT**.

## 🚀 Getting started

#### Add documents <!-- omit in toc -->

```ruby
require 'meilisearch'

client = MeiliSearch::Client.new('http://127.0.0.1:7700', 'masterKey')
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

With the `updateId`, you can check the status (`processed` or `failed`) of your documents addition thanks to this [method](#update-status).

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

## 🤖 Compatibility with MeiliSearch

This package is compatible with the following MeiliSearch versions:
- `v0.11.X`

## 🎬 Examples

All HTTP routes of MeiliSearch are accessible via methods in this SDK.</br>
You can check out [the API documentation](https://docs.meilisearch.com/references/).

### Indexes

#### Create an index <!-- omit in toc -->

```ruby
# Create an index
client.create_index('books')
# Create an index and give the primary-key
client.create_index('books', primaryKey: 'book_id')
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
            "book_id": 456,
            "title": "Le Petit Prince",
            "_formatted": {
                "book_id": 456,
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

If you want to contribute, this section describes the steps to follow.

Thank you for your interest in a MeiliSearch tool! ♥️

### Install dependencies

```bash
$ bundle install
```

### Tests

Each PR should pass the tests to be accepted.

```bash
# Tests
$ docker run -p 7700:7700 getmeili/meilisearch:latest ./meilisearch --master-key=masterKey --no-analytics
$ bundle exec rspec
```

To launch a specific folder or file:

```bash
$ bundle exec rspec spec/meilisearch/index/base_spec.rb
```

To launch a single test in a specific file:

```bash
$ bundle exec rspec spec/meilisearch/index/search_spec.rb -e 'does a basic search in index'
```

### Linter

Each PR should pass the linter to be accepted.

```bash
# Check the linter error
$ bundle exec rubocop lib/ spec/
# Auto-correct
$ bundle exec rubocop -a lib/ spec/
```

Once you think the remaining linter errors as valid, do not add any `rubocop` comment line in the code.<br>
This project uses a `rubocop_todo.yml` file that is generated. Do not modify this file manually.<br>
To update it, run the following command:

```bash
$ bundle exec rubocop --auto-gen-config
```

### Want to debug?

You can use the [`byebug` gem](https://github.com/deivid-rodriguez/byebug) that is already imported in the all files of this package.

To create a breakpoint, just add this line in you code:

```ruby
...
byebug
...
```

### Release

MeiliSearch tools follow the [Semantic Versioning Convention](https://semver.org/).

You must do a PR modifying the file [`lib/meilisearch/version.rb`](/lib/meilisearch/version.rb) with the right version:

```ruby
VERSION = 'X.X.X'
```

Once the changes are merged on `master`, you can publish the current draft release via the [GitHub interface](https://github.com/meilisearch/meilisearch-ruby/releases).

A GitHub Action will be triggered and push the new gem on [RubyGems](https://rubygems.org/gems/meilisearch).

<hr>

**MeiliSearch** provides and maintains many **SDKs and Integration tools** like this one. We want to provide everyone with an **amazing search experience for any kind of project**. If you want to contribute, make suggestions, or just know what's going on right now, visit us in the [integration-guides](https://github.com/meilisearch/integration-guides) repository.
