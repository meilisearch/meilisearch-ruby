<p align="center">
  <img src="https://res.cloudinary.com/meilisearch/image/upload/v1587402338/SDKs/meilisearch_ruby.svg" alt="MeiliSearch-Ruby" width="200" height="200" />
</p>

<h1 align="center">MeiliSearch Ruby</h1>

<h4 align="center">
  <a href="https://github.com/meilisearch/MeiliSearch">MeiliSearch</a> |
  <a href="https://docs.meilisearch.com">Documentation</a> |
  <a href="https://slack.meilisearch.com">Slack</a> |
  <a href="https://roadmap.meilisearch.com/tabs/1-under-consideration">Roadmap</a> |
  <a href="https://www.meilisearch.com">Website</a> |
  <a href="https://docs.meilisearch.com/faq">FAQ</a>
</h4>

<p align="center">
  <a href="https://badge.fury.io/rb/meilisearch"><img src="https://badge.fury.io/rb/meilisearch.svg" alt="Latest Stable Version"></a>
  <a href="https://github.com/meilisearch/meilisearch-ruby/actions"><img src="https://github.com/meilisearch/meilisearch-ruby/workflows/Tests/badge.svg" alt="Test"></a>
  <a href="https://github.com/meilisearch/meilisearch-ruby/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-informational" alt="License"></a>
  <a href="https://app.bors.tech/repositories/28781"><img src="https://bors.tech/images/badge_small.svg" alt="Bors enabled"></a>
</p>

<p align="center">⚡ The MeiliSearch API client written for Ruby 💎</p>

**MeiliSearch Ruby** is the MeiliSearch API client for Ruby developers.

**MeiliSearch** is an open-source search engine. [Discover what MeiliSearch is!](https://github.com/meilisearch/MeiliSearch)

## Table of Contents <!-- omit in toc -->

- [📖 Documentation](#-documentation)
- [🔧 Installation](#-installation)
- [🚀 Getting Started](#-getting-started)
- [🤖 Compatibility with MeiliSearch](#-compatibility-with-meilisearch)
- [💡 Learn More](#-learn-more)
- [⚙️ Development Workflow and Contributing](#️-development-workflow-and-contributing)

## 📖 Documentation

See our [Documentation](https://docs.meilisearch.com/learn/tutorials/getting_started.html) or our [API References](https://docs.meilisearch.com/reference/api/).

## 🔧 Installation

This package requires Ruby version 2.6.0 or later.

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

There are many easy ways to [download and run a MeiliSearch instance](https://docs.meilisearch.com/reference/features/installation.html#download-and-launch).

For example, if you use Docker:

```bash
$ docker pull getmeili/meilisearch:latest # Fetch the latest version of MeiliSearch image from Docker Hub
$ docker run -it --rm -p 7700:7700 getmeili/meilisearch:latest ./meilisearch --master-key=masterKey
```

NB: you can also download MeiliSearch from **Homebrew** or **APT**.

## 🚀 Getting Started

#### Add documents <!-- omit in toc -->

```ruby
require 'meilisearch'

client = MeiliSearch::Client.new('http://127.0.0.1:7700', 'masterKey')

# An index is where the documents are stored.
index = client.index('books')

documents = [
  { book_id: 123,  title: 'Pride and Prejudice' },
  { book_id: 456,  title: 'Le Petit Prince' },
  { book_id: 1,    title: 'Alice In Wonderland' },
  { book_id: 1344, title: 'The Hobbit' },
  { book_id: 4,    title: 'Harry Potter and the Half-Blood Prince' },
  { book_id: 42,   title: 'The Hitchhiker\'s Guide to the Galaxy' }
]
# If the index 'books' does not exist, MeiliSearch creates it when you first add the documents.
index.add_documents(documents) # => { "updateId": 0 }
```

With the `updateId`, you can check the status (`enqueued`, `processed` or `failed`) of your documents addition using the [update endpoint](https://docs.meilisearch.com/reference/api/updates.html#get-an-update-status).

💡 To customize the `Client`, for example, increasing the default timeout, please check out [this section](https://github.com/meilisearch/meilisearch-ruby/wiki/Client-Options) of the Wiki.

#### Basic Search <!-- omit in toc -->

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

#### Custom search <!-- omit in toc -->

All the supported options are described in the [search parameters](https://docs.meilisearch.com/reference/features/search_parameters.html) section of the documentation.

```ruby
index.search('prince',
  {
    filters: 'book_id > 10',
    attributesToHighlight: ['*']
  }
)
```

JSON output:

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
    "limit": 20,
    "processingTimeMs": 0,
    "query": "prince"
}
```

## 🤖 Compatibility with MeiliSearch

This package only guarantees the compatibility with the [version v0.19.0 of MeiliSearch](https://github.com/meilisearch/MeiliSearch/releases/tag/v0.19.0).

## 💡 Learn More

The following sections may interest you:

- **Manipulate documents**: see the [API references](https://docs.meilisearch.com/reference/api/documents.html) or read more about [documents](https://docs.meilisearch.com/learn/core_concepts/documents.html).
- **Search**: see the [API references](https://docs.meilisearch.com/reference/api/search.html) or follow our guide on [search parameters](https://docs.meilisearch.com/reference/features/search_parameters.html).
- **Manage the indexes**: see the [API references](https://docs.meilisearch.com/reference/api/indexes.html) or read more about [indexes](https://docs.meilisearch.com/learn/core_concepts/indexes.html).
- **Configure the index settings**: see the [API references](https://docs.meilisearch.com/reference/api/settings.html) or follow our guide on [settings parameters](https://docs.meilisearch.com/reference/features/settings.html).

📖 Also, check out the [Wiki](https://github.com/meilisearch/meilisearch-ruby/wiki) of this repository to know what this SDK provdes!

## ⚙️ Development Workflow and Contributing

Any new contribution is more than welcome in this project!

If you want to know more about the development workflow or want to contribute, please visit our [contributing guidelines](/CONTRIBUTING.md) for detailed instructions!

<hr>

**MeiliSearch** provides and maintains many **SDKs and Integration tools** like this one. We want to provide everyone with an **amazing search experience for any kind of project**. If you want to contribute, make suggestions, or just know what's going on right now, visit us in the [integration-guides](https://github.com/meilisearch/integration-guides) repository.
