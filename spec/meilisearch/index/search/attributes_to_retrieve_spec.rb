# frozen_string_literal: true

RSpec.describe 'Meilisearch::Index - Search with attributes to retrieve' do
  include_context 'search books with genre'

  it 'does a custom search with one attributes_to_retrieve' do
    response = index.search('the', attributes_to_retrieve: ['title'])
    expect(response).to be_a(Hash)
    expect(response.keys).to include(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(4)
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).not_to have_key('objectId')
    expect(response['hits'].first).not_to have_key('genre')
  end

  it 'does a custom search with multiple attributes_to_retrieve' do
    response = index.search('the', attributes_to_retrieve: ['title', 'genre'])
    expect(response).to be_a(Hash)
    expect(response.keys).to include(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(4)
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).not_to have_key('objectId')
    expect(response['hits'].first).to have_key('genre')
  end

  it 'does a custom search with all attributes_to_retrieve' do
    response = index.search('the', attributes_to_retrieve: ['*'])
    expect(response).to be_a(Hash)
    expect(response.keys).to include(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(4)
    expect(response['hits'].first).to have_key('objectId')
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).to have_key('genre')
  end

  it 'does a placeholder search with one attributes_to_retrieve' do
    response = index.search('', attributes_to_retrieve: ['title'])
    expect(response).to be_a(Hash)
    expect(response.keys).to include(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(documents.count)
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).not_to have_key('objectId')
    expect(response['hits'].first).not_to have_key('genre')
  end

  it 'does a placeholder search with multiple attributes_to_retrieve' do
    response = index.search('', attributes_to_retrieve: ['title', 'genre'])
    expect(response).to be_a(Hash)
    expect(response.keys).to include(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(documents.count)
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).not_to have_key('objectId')
    expect(response['hits'].first).to have_key('genre')
  end

  it 'does a placeholder search with all attributes_to_retrieve' do
    response = index.search('', attributes_to_retrieve: ['*'])
    expect(response).to be_a(Hash)
    expect(response.keys).to include(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(documents.count)
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).to have_key('objectId')
    expect(response['hits'].first).to have_key('genre')
  end
end
