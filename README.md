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
  - [Client](#client)
  - [Indexes](#indexes)
  - [Documents](#documents)
  - [Update status](#update-status)
  - [Search](#search)
- [⚙️ Development Workflow and Contributing](#️-development-workflow-and-contributing)

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
$ docker pull getmeili/meilisearch:latest # Fetch the latest version of MeiliSearch image from Docker Hub
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
- `v0.14.X`
- `v0.13.X`

## 🎬 Examples

All HTTP routes of MeiliSearch are accessible via methods in this SDK.</br>
You can check out [the API documentation](https://docs.meilisearch.com/references/).

### Client

```ruby
# Default client
client = MeiliSearch::Client.new('http://127.0.0.1:7700', 'masterKey')
# Custom client
client = MeiliSearch::Client.new('http://127.0.0.1:7700', 'masterKey', timeout: 2, max_retries: 2)
```

`timeout` - default value: `1` second<br>
The time in seconds before a `Timeout::Error` is raised.

`max_retries` - default value: `0`<br>
If the HTTP request times out, this number of retries will be applied.

### Indexes

#### Create an index <!-- omit in toc -->

```ruby
# Create an index
client.create_index('books')
# Create an index and give the primary-key
client.create_index('books', primaryKey: 'book_id')
# Create an index or get the already existing one
client.create_index('books')
client.get_or_create_index('books', primaryKey: 'book_id')
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

## ⚙️ Development Workflow and Contributing

Any new contribution is more than welcome in this project!

If you want to know more about the development workflow or want to contribute, please visit our [contributing guidelines](/CONTRIBUTING.md) for detailed instructions!

<hr>

**MeiliSearch** provides and maintains many **SDKs and Integration tools** like this one. We want to provide everyone with an **amazing search experience for any kind of project**. If you want to contribute, make suggestions, or just know what's going on right now, visit us in the [integration-guides](https://github.com/meilisearch/integration-guides) repository.
