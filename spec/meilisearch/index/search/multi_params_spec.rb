# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Multi-paramaters search' do
  include_context 'search books with genre'

  before { index.update_filterable_attributes(['genre']).await }

  it 'does a custom search with attributes to crop, filter and attributes to highlight' do
    response = index.search('prince',
                            {
                              attributes_to_crop: ['title'],
                              crop_length: 2,
                              filter: 'genre = adventure',
                              attributes_to_highlight: ['title']
                            })
    expect(response['hits'].count).to be(1)
    expect(response['hits'].first).to have_key('_formatted')
    expect(response['hits'].first['_formatted']['title']).to eq('…Petit <em>Prince</em>')
  end

  it 'does a custom search with attributes_to_retrieve and a limit' do
    response = index.search('the', attributes_to_retrieve: ['title', 'genre'], limit: 2)
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(2)
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first).not_to have_key('objectId')
    expect(response['hits'].first).to have_key('genre')
  end

  it 'does a placeholder search with filter and offset' do
    response = index.search('', { filter: 'genre = adventure', offset: 2 })
    expect(response['hits'].count).to eq(1)
  end

  it 'does a custom search with limit and attributes to highlight' do
    response = index.search('the', { limit: 1, attributes_to_highlight: ['*'] })
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(1)
    expect(response['hits'].first).to have_key('_formatted')
  end

  it 'does a custom search with filter, attributes_to_retrieve and attributes_to_highlight' do
    index.update_filterable_attributes(['genre']).await
    response = index.search('prinec',
                            {
                              filter: ['genre = fantasy'],
                              attributes_to_retrieve: ['title'],
                              attributes_to_highlight: ['*']
                            })
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['estimatedTotalHits']).to eq(1)
    expect(response['hits'].first).to have_key('_formatted')
    expect(response['hits'].first).not_to have_key('objectId')
    expect(response['hits'].first).not_to have_key('genre')
    expect(response['hits'].first).to have_key('title')
    expect(response['hits'].first['_formatted']['title']).to eq('Harry Potter and the Half-Blood <em>Prince</em>')
  end

  it 'does a custom search with facets and limit' do
    index.update_filterable_attributes(['genre']).await
    response = index.search('prinec', facets: ['genre'], limit: 1)

    expect(response.keys).to contain_exactly(
      *DEFAULT_SEARCH_RESPONSE_KEYS,
      'facetDistribution',
      'facetStats'
    )
    expect(response['estimatedTotalHits']).to eq(2)
    expect(response['hits'].count).to eq(1)
    expect(response['facetDistribution'].keys).to contain_exactly('genre')
    expect(response['facetDistribution']['genre'].keys).to contain_exactly('adventure', 'fantasy')
    expect(response['facetDistribution']['genre']['adventure']).to eq(1)
    expect(response['facetDistribution']['genre']['fantasy']).to eq(1)
  end
end
