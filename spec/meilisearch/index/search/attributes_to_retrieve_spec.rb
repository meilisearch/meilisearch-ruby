# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Search with attributes to retrieve' do
  include_context 'search books with genre'

  it 'does a custom search with one attributesToRetrieve' do
    response = index.search('the', attributesToRetrieve: ['title'])
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(3)
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).not_to have_key('objectId')
    expect(response['hits'].first).not_to have_key('genre')
  end

  it 'does a custom search with multiple attributesToRetrieve' do
    response = index.search('the', attributesToRetrieve: ['title', 'genre'])
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(3)
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).not_to have_key('objectId')
    expect(response['hits'].first).to have_key('genre')
  end

  it 'does a custom search with all attributesToRetrieve' do
    response = index.search('the', attributesToRetrieve: ['*'])
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(3)
    expect(response['hits'].first).to have_key('objectId')
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).to have_key('genre')
  end

  it 'does a placeholder search with one attributesToRetrieve' do
    response = index.search('', attributesToRetrieve: ['title'])
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(documents.count)
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).not_to have_key('objectId')
    expect(response['hits'].first).not_to have_key('genre')
  end

  it 'does a placeholder search with multiple attributesToRetrieve' do
    response = index.search('', attributesToRetrieve: ['title', 'genre'])
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(documents.count)
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).not_to have_key('objectId')
    expect(response['hits'].first).to have_key('genre')
  end

  it 'does a placeholder search with all attributesToRetrieve' do
    response = index.search('', attributesToRetrieve: ['*'])
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(documents.count)
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).to have_key('objectId')
    expect(response['hits'].first).to have_key('genre')
  end
end
