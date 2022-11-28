<p align="center">
  <img src="https://raw.githubusercontent.com/meilisearch/integration-guides/main/assets/logos/meilisearch_ruby.svg" alt="Meilisearch-Ruby" width="200" height="200" />
</p>

<h1 align="center">Meilisearch Ruby</h1>

<h4 align="center">
  <a href="https://github.com/meilisearch/meilisearch">Meilisearch</a> |
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
  <a href="https://ms-bors.herokuapp.com/repositories/6"><img src="https://bors.tech/images/badge_small.svg" alt="Bors enabled"></a>
</p>

<p align="center">⚡ The Meilisearch API client written for Ruby 💎</p>

**Meilisearch Ruby** is the Meilisearch API client for Ruby developers.

**Meilisearch** is an open-source search engine. [Learn more about Meilisearch.](https://github.com/meilisearch/meilisearch)

## Table of Contents <!-- omit in toc -->

- [📖 Documentation](#-documentation)
- [🔧 Installation](#-installation)
- [🚀 Getting started](#-getting-started)
- [🤖 Compatibility with Meilisearch](#-compatibility-with-meilisearch)
- [💡 Learn more](#-learn-more)
- [⚙️ Contributing](#️-contributing)

## 📖 Documentation

This readme contains all the documentation you need to start using this Meilisearch SDK.

For general information on how to use Meilisearch—such as our API reference, tutorials, guides, and in-depth articles—refer to our [main documentation website](https://docs.meilisearch.com/).


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

There are many easy ways to [download and run a Meilisearch instance](https://docs.meilisearch.com/reference/features/installation.html#download-and-launch).

For example, using the `curl` command in your [Terminal](https://itconnect.uw.edu/learn/workshops/online-tutorials/web-publishing/what-is-a-terminal/):

```sh
#Install Meilisearch
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

With the `uid`, you can check the status (`enqueued`, `processing`, `succeeded` or `failed`) of your documents addition using the [task](https://docs.meilisearch.com/reference/api/tasks.html#get-task).

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

All the supported options are described in the [search parameters](https://docs.meilisearch.com/reference/features/search_parameters.html) section of the documentation.

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

Note that Meilisearch will rebuild your index whenever you update `filterableAttributes`. Depending on the size of your dataset, this might take time. You can track the process using the [tasks](https://docs.meilisearch.com/reference/api/tasks.html#get-task)).

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

## 🤖 Compatibility with Meilisearch

This package only guarantees the compatibility with the [version v0.30.0 of Meilisearch](https://github.com/meilisearch/meilisearch/releases/tag/v0.30.0).

## 💡 Learn more

The following sections in our main documentation website may interest you:

- **Manipulate documents**: see the [API references](https://docs.meilisearch.com/reference/api/documents.html) or read more about [documents](https://docs.meilisearch.com/learn/core_concepts/documents.html).
- **Search**: see the [API references](https://docs.meilisearch.com/reference/api/search.html) or follow our guide on [search parameters](https://docs.meilisearch.com/reference/features/search_parameters.html).
- **Manage the indexes**: see the [API references](https://docs.meilisearch.com/reference/api/indexes.html) or read more about [indexes](https://docs.meilisearch.com/learn/core_concepts/indexes.html).
- **Configure the index settings**: see the [API references](https://docs.meilisearch.com/reference/api/settings.html) or follow our guide on [settings parameters](https://docs.meilisearch.com/reference/features/settings.html).

📖 Also, check out the [Wiki](https://github.com/meilisearch/meilisearch-ruby/wiki) of this repository to know what this SDK provdes!

## ⚙️ Contributing

Any new contribution is more than welcome in this project!

If you want to know more about the development workflow or want to contribute, please visit our [contributing guidelines](/CONTRIBUTING.md) for detailed instructions!

<hr>

**Meilisearch** provides and maintains many **SDKs and Integration tools** like this one. We want to provide everyone with an **amazing search experience for any kind of project**. If you want to contribute, make suggestions, or just know what's going on right now, visit us in the [integration-guides](https://github.com/meilisearch/integration-guides) repository.
