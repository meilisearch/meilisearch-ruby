<p align="center">
  <img src="https://res.cloudinary.com/meilisearch/image/upload/v1587402338/SDKs/meilisearch_ruby.svg" alt="MeiliSearch-Ruby" width="200" height="200" />
</p>

<h1 align="center">MeiliSearch Ruby</h1>

<h4 align="center">
  <a href="https://github.com/meilisearch/MeiliSearch">MeiliSearch</a> |
  <a href="https://docs.meilisearch.com">Documentation</a> |
  <a href="https://www.meilisearch.com">Website</a> |
  <a href="https://blog.meilisearch.com">Blog</a> |
  <a href="https://twitter.com/meilisearch">Twitter</a> |
  <a href="https://docs.meilisearch.com/faq">FAQ</a>
</h4>

<p align="center">
  <a href="https://badge.fury.io/rb/meilisearch"><img src="https://badge.fury.io/rb/meilisearch.svg" alt="Latest Stable Version"></a>
  <a href="https://github.com/meilisearch/meilisearch-ruby/actions"><img src="https://github.com/meilisearch/meilisearch-ruby/workflows/Test/badge.svg" alt="Test"></a>
  <a href="https://github.com/meilisearch/meilisearch-ruby/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-informational" alt="License"></a>
  <a href="https://slack.meilisearch.com"><img src="https://img.shields.io/badge/slack-MeiliSearch-blue.svg?logo=slack" alt="Slack"></a>
  <a href="https://app.bors.tech/repositories/28781"><img src="https://bors.tech/images/badge_small.svg" alt="Bors enabled"></a>
</p>

<p align="center">⚡ The MeiliSearch API client written for Ruby 💎</p>

**MeiliSearch Ruby** is the MeiliSearch API client for Ruby developers. **MeiliSearch** is a powerful, fast, open-source, easy to use and deploy search engine. Both searching and indexing are highly customizable. Features such as typo-tolerance, filters, facets, and synonyms are provided out-of-the-box.

## Table of Contents <!-- omit in toc -->

- [📖 Documentation](#-documentation)
- [🔧 Installation](#-installation)
- [🚀 Getting Started](#-getting-started)
- [🤖 Compatibility with MeiliSearch](#-compatibility-with-meilisearch)
- [💡 Learn More](#-learn-more)
- [⚙️ Development Workflow and Contributing](#️-development-workflow-and-contributing)

## 📖 Documentation

See our [Documentation](https://docs.meilisearch.com/guides/introduction/quick_start_guide.html) or our [API References](https://docs.meilisearch.com/references/).

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

## 🚀 Getting Started

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

With the `updateId`, you can check the status (`enqueued`, `processed` or `failed`) of your documents addition using the [update endpoint](https://docs.meilisearch.com/references/updates.html#get-an-update-status).

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

All the supported options are described in the [search parameters](https://docs.meilisearch.com/guides/advanced_guides/search_parameters.html) section of the documentation.

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

This package only guarantees the compatibility with the [version v0.15.0 of MeiliSearch](https://github.com/meilisearch/MeiliSearch/releases/tag/v0.15.0).

## 💡 Learn More

The following sections may interest you:

- **Manipulate documents**: see the [API references](https://docs.meilisearch.com/references/documents.html) or read more about [documents](https://docs.meilisearch.com/guides/main_concepts/documents.html).
- **Search**: see the [API references](https://docs.meilisearch.com/references/search.html) or follow our guide on [search parameters](https://docs.meilisearch.com/guides/advanced_guides/search_parameters.html).
- **Manage the indexes**: see the [API references](https://docs.meilisearch.com/references/indexes.html) or read more about [indexes](https://docs.meilisearch.com/guides/main_concepts/indexes.html).
- **Configure the index settings**: see the [API references](https://docs.meilisearch.com/references/settings.html) or follow our guide on [settings parameters](https://docs.meilisearch.com/guides/advanced_guides/settings.html).

## ⚙️ Development Workflow and Contributing

Any new contribution is more than welcome in this project!

If you want to know more about the development workflow or want to contribute, please visit our [contributing guidelines](/CONTRIBUTING.md) for detailed instructions!

<hr>

**MeiliSearch** provides and maintains many **SDKs and Integration tools** like this one. We want to provide everyone with an **amazing search experience for any kind of project**. If you want to contribute, make suggestions, or just know what's going on right now, visit us in the [integration-guides](https://github.com/meilisearch/integration-guides) repository.
