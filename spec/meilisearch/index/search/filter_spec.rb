# frozen_string_literal: true

RSpec.describe 'Meilisearch::Index - Filtered search' do
  include_context 'search books with author, genre, year'

  before { index.update_filterable_attributes(['genre', 'year', 'author']).await }

  it 'does a custom search with one filter' do
    response = index.search('le', { filter: 'genre = romance' })
    expect(response['hits'].count).to eq(1)
    expect(response['hits'].first['objectId']).to eq(2)
  end

  it 'does a custom search with a numerical value filter' do
    response = index.search('potter', { filter: 'year = 2007' })
    expect(response['hits'].count).to eq(1)
    expect(response['hits'].first['objectId']).to eq(2056)
  end

  it 'does a custom search with multiple filter' do
    response = index.search('prince', { filter: 'year > 1930 AND author = "Antoine de Saint-Exupéry"' })
    expect(response['hits'].count).to eq(1)
    expect(response['hits'].first['objectId']).to eq(456)
  end

  it 'does a placeholder search with multiple filter' do
    response = index.search('', { filter: 'author = "J. K. Rowling" OR author = "George R. R. Martin"' })
    expect(response['hits'].count).to eq(3)
  end

  it 'does a placeholder search with numerical values filter' do
    response = index.search('', { filter: 'year < 2000 AND year > 1990' })
    expect(response['hits'].count).to eq(1)
    expect(response['hits'].first['year']).to eq(1996)
  end

  it 'does a placeholder search with multiple filter and different type of values' do
    response = index.search('', { filter: 'author = "J. K. Rowling" AND year > 2006' })
    expect(response['hits'].count).to eq(1)
    expect(response['hits'].first['objectId']).to eq(2056)
  end

  it 'does a custom search with filter and array syntax' do
    response = index.search('prinec', filter: ['genre = fantasy'])
    expect(response.keys).to include(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['estimatedTotalHits']).to eq(1)
    expect(response['hits'][0]['objectId']).to eq(4)
  end

  it 'does a custom search with multiple filter and array syntax' do
    response = index.search('potter', filter: ['genre = fantasy', ['year = 2005']])
    expect(response.keys).to include(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['estimatedTotalHits']).to eq(1)
    expect(response['hits'][0]['objectId']).to eq(4)
  end
end
