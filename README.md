<p align="center">
  <img src="https://raw.githubusercontent.com/meilisearch/integration-guides/main/assets/logos/meilisearch_ruby.svg" alt="Meilisearch-Ruby" width="200" height="200" />
</p>

<h1 align="center">Meilisearch Ruby</h1>

<h4 align="center">
  <a href="https://github.com/meilisearch/meilisearch">Meilisearch</a> |
  <a href="https://www.meilisearch.com/cloud?utm_campaign=oss&utm_source=github&utm_medium=meilisearch-ruby">Meilisearch Cloud</a> |
  <a href="https://docs.meilisearch.com">Documentation</a> |
  <a href="https://discord.meilisearch.com">Discord</a> |
  <a href="https://roadmap.meilisearch.com/tabs/1-under-consideration">Roadmap</a> |
  <a href="https://www.meilisearch.com">Website</a> |
  <a href="https://www.meilisearch.com/docs/faq">FAQ</a>
</h4>

<p align="center">
  <a href="https://badge.fury.io/rb/meilisearch"><img src="https://badge.fury.io/rb/meilisearch.svg" alt="Latest Stable Version"></a>
  <a href="https://github.com/meilisearch/meilisearch-ruby/actions"><img src="https://github.com/meilisearch/meilisearch-ruby/workflows/Tests/badge.svg" alt="Test"></a>
  <a href="https://app.codecov.io/gh/meilisearch/meilisearch-ruby/tree/main" >
    <img src="https://codecov.io/gh/meilisearch/meilisearch-ruby/branch/main/graph/badge.svg?token=9J7LRP11IR"/>
  </a>
  <a href="https://github.com/meilisearch/meilisearch-ruby/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-informational" alt="License"></a>
  <a href="https://ms-bors.herokuapp.com/repositories/6"><img src="https://bors.tech/images/badge_small.svg" alt="Bors enabled"></a>
</p>

<p align="center">⚡ The Meilisearch API client written for Ruby 💎</p>

**Meilisearch Ruby** is the Meilisearch API client for Ruby developers.

**Meilisearch** is an open-source search engine. [Learn more about Meilisearch.](https://github.com/meilisearch/meilisearch)

## Table of Contents <!-- omit in toc -->

- [📖 Documentation](#-documentation)
- [⚡ Supercharge your Meilisearch experience](#-supercharge-your-meilisearch-experience)
- [🔧 Installation](#-installation)
- [🚀 Getting started](#-getting-started)
- [🤖 Compatibility with Meilisearch](#-compatibility-with-meilisearch)
- [💡 Learn more](#-learn-more)
- [⚙️ Contributing](#️-contributing)

## 📖 Documentation

This readme contains all the documentation you need to start using this Meilisearch SDK.

For general information on how to use Meilisearch—such as our API reference, tutorials, guides, and in-depth articles—refer to our [main documentation website](https://www.meilisearch.com/docs/).


## ⚡ Supercharge your Meilisearch experience

Say goodbye to server deployment and manual updates with [Meilisearch Cloud](https://www.meilisearch.com/cloud?utm_campaign=oss&utm_source=github&utm_medium=meilisearch-ruby). Get started with a 14-day free trial! No credit card required.

## 🔧 Installation

This package requires Ruby version 2.6.0 or later.

With `gem` in command line:
```bash
gem install meilisearch
```

In your `Gemfile` with [bundler](https://bundler.io/):
```ruby
source 'https://rubygems.org'

gem 'meilisearch'
```

### Run Meilisearch <!-- omit in toc -->

There are many easy ways to [download and run a Meilisearch instance](https://www.meilisearch.com/docs/learn/getting_started/quick_start#setup-and-installation).

For example, using the `curl` command in your [Terminal](https://itconnect.uw.edu/learn/workshops/online-tutorials/what-is-a-terminal/):

```sh
# Install Meilisearch
curl -L https://install.meilisearch.com | sh

# Launch Meilisearch
./meilisearch --master-key=masterKey
```

NB: you can also download Meilisearch from **Homebrew** or **APT** or even run it using **Docker**.

## 🚀 Getting started

#### Add documents <!-- omit in toc -->

```ruby
require 'meilisearch'

client = MeiliSearch::Client.new('http://127.0.0.1:7700', 'masterKey')

# An index is where the documents are stored.
index = client.index('movies')

documents = [
  { id: 1, title: 'Carol', genres: ['Romance', 'Drama'] },
  { id: 2, title: 'Wonder Woman', genres: ['Action', 'Adventure'] },
  { id: 3, title: 'Life of Pi', genres: ['Adventure', 'Drama'] },
  { id: 4, title: 'Mad Max: Fury Road', genres: ['Adventure', 'Science Fiction'] },
  { id: 5, title: 'Moana', genres: ['Fantasy', 'Action']},
  { id: 6, title: 'Philadelphia', genres: ['Drama'] },
]
# If the index 'movies' does not exist, Meilisearch creates it when you first add the documents.
index.add_documents(documents) # => { "uid": 0 }
```

With the `uid`, you can check the status (`enqueued`, `canceled`, `processing`, `succeeded` or `failed`) of your documents addition using the [task](https://www.meilisearch.com/docs/reference/api/tasks#get-tasks).

💡 To customize the `Client`, for example, increasing the default timeout, please check out [this section](https://github.com/meilisearch/meilisearch-ruby/wiki/Client-Options) of the Wiki.

#### Basic Search <!-- omit in toc -->

``` ruby
# Meilisearch is typo-tolerant:
puts index.search('carlo')
```
Output:

```ruby
{
  "hits" => [{
    "id" => 1,
    "title" => "Carol"
  }],
  "offset" => 0,
  "limit" => 20,
  "processingTimeMs" => 1,
  "query" => "carlo"
}
```

#### Custom search <!-- omit in toc -->

All the supported options are described in the [search parameters](https://www.meilisearch.com/docs/reference/api/search#search-parameters) section of the documentation.

```ruby
index.search(
  'wonder',
  attributes_to_highlight: ['*']
)
```

JSON output:

```json
{
    "hits": [
        {
            "id": 2,
            "title": "Wonder Woman",
            "_formatted": {
                "id": 2,
                "title": "<em>Wonder</em> Woman"
            }
        }
    ],
    "offset": 0,
    "limit": 20,
    "processingTimeMs": 0,
    "query": "wonder"
}
```

#### Custom Search With Filters <!-- omit in toc -->

If you want to enable filtering, you must add your attributes to the `filterableAttributes` index setting.

```ruby
index.update_filterable_attributes([
  'id',
  'genres'
])
```

You only need to perform this operation once.

Note that Meilisearch will rebuild your index whenever you update `filterableAttributes`. Depending on the size of your dataset, this might take time. You can track the process using the [tasks](https://www.meilisearch.com/docs/reference/api/tasks#get-tasks)).

Then, you can perform the search:

```ruby
index.search('wonder', { filter: ['id > 1 AND genres = Action'] })
```

JSON output:

```json
{
  "hits": [
    {
      "id": 2,
      "title": "Wonder Woman",
      "genres": [
        "Action",
        "Adventure"
      ]
    }
  ],
  "estimatedTotalHits": 1,
  "query": "wonder",
  "limit": 20,
  "offset": 0,
  "processingTimeMs": 0
}
```

#### Display ranking details at search

JSON output:

```json
{
  "hits": [
    {
      "id": 15359,
      "title": "Wonder Woman",
      "_rankingScoreDetails": {
        "words": {
          "order": 0,
          "matchingWords": 2,
          "maxMatchingWords": 2,
          "score": 1.0
        },
        "typo": {
          "order": 1,
          "typoCount": 0,
          "maxTypoCount": 2,
          "score": 1.0
        },
        "proximity": {
          "order": 2,
          "score": 1.0
        },
        "attribute": {
          "order": 3,
          "attributeRankingOrderScore": 0.8181818181818182,
          "queryWordDistanceScore": 1.0,
          "score": 0.8181818181818182
        },
        "exactness": {
          "order": 4,
          "matchType": "exactMatch",
          "score": 1.0
        }
      }
    }
  ]
}
```

You can enable it by querying PATCH /experimental-features with { "scoreDetails": true }

This feature is only available with Meilisearch v1.3 and newer (optional).

## 🤖 Compatibility with Meilisearch

This package guarantees compatibility with [version v1.x of Meilisearch](https://github.com/meilisearch/meilisearch/releases/latest), but some features may not be present. Please check the [issues](https://github.com/meilisearch/meilisearch-ruby/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22+label%3Aenhancement) for more info.

## 💡 Learn more

The following sections in our main documentation website may interest you:

- **Manipulate documents**: see the [API references](https://www.meilisearch.com/docs/reference/api/documents) or read more about [documents](https://www.meilisearch.com/docs/learn/core_concepts/documents).
- **Search**: see the [API references](https://www.meilisearch.com/docs/reference/api/search) or follow our guide on [search parameters](https://www.meilisearch.com/docs/reference/api/search#search-parameters).
- **Manage the indexes**: see the [API references](https://www.meilisearch.com/docs/reference/api/indexes) or read more about [indexes](https://www.meilisearch.com/docs/learn/core_concepts/indexes).
- **Configure the index settings**: see the [API references](https://www.meilisearch.com/docs/reference/api/settings) or follow our guide on [settings parameters](https://www.meilisearch.com/docs/reference/api/settings).

📖 Also, check out the [Wiki](https://github.com/meilisearch/meilisearch-ruby/wiki) of this repository to know what this SDK provides!

## ⚙️ Contributing

Any new contribution is more than welcome in this project!

If you want to know more about the development workflow or want to contribute, please visit our [contributing guidelines](/CONTRIBUTING.md) for detailed instructions!

<hr>

**Meilisearch** provides and maintains many **SDKs and Integration tools** like this one. We want to provide everyone with an **amazing search experience for any kind of project**. If you want to contribute, make suggestions, or just know what's going on right now, visit us in the [integration-guides](https://github.com/meilisearch/integration-guides) repository.
