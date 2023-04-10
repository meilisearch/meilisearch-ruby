# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Search with facets' do
  include_context 'search books with author, genre, year'

  before do
    response = index.update_filterable_attributes(['genre', 'year', 'author'])
    index.wait_for_task(response['taskUid'])
  end

  it 'does a custom search with facets' do
    response = index.search('prinec', facets: ['genre', 'author'])
    expect(response.keys).to contain_exactly(
      *DEFAULT_SEARCH_RESPONSE_KEYS,
      'facetDistribution',
      'facetStats'
    )
    expect(response['estimatedTotalHits']).to eq(2)
    expect(response['facetDistribution'].keys).to contain_exactly('genre', 'author')
    expect(response['facetDistribution']['genre'].keys).to contain_exactly('adventure', 'fantasy')
    expect(response['facetDistribution']['genre']['adventure']).to eq(1)
    expect(response['facetDistribution']['genre']['fantasy']).to eq(1)
    expect(response['facetDistribution']['author']['J. K. Rowling']).to eq(1)
    expect(response['facetDistribution']['author']['Antoine de Saint-Exupéry']).to eq(1)
  end

  it 'does a placeholder search with facets' do
    response = index.search('', facets: ['genre', 'author'])
    expect(response.keys).to contain_exactly(
      *DEFAULT_SEARCH_RESPONSE_KEYS,
      'facetDistribution',
      'facetStats'
    )
    expect(response['estimatedTotalHits']).to eq(documents.count)
    expect(response['facetDistribution'].keys).to contain_exactly('genre', 'author')
    expect(response['facetDistribution']['genre'].keys).to contain_exactly('romance', 'adventure', 'fantasy')
    expect(response['facetDistribution']['genre']['romance']).to eq(2)
    expect(response['facetDistribution']['genre']['adventure']).to eq(3)
    expect(response['facetDistribution']['genre']['fantasy']).to eq(3)
    expect(response['facetDistribution']['author']['J. K. Rowling']).to eq(2)
  end

  it 'does a placeholder search with facets on number' do
    response = index.search('', facets: ['year'])
    expect(response.keys).to contain_exactly(
      *DEFAULT_SEARCH_RESPONSE_KEYS,
      'facetDistribution',
      'facetStats'
    )
    expect(response['estimatedTotalHits']).to eq(documents.count)
    expect(response['facetDistribution'].keys).to contain_exactly('year')
    expect(response['facetDistribution']['year'].keys).to contain_exactly(*documents.map { |o| o[:year].to_s })
    expect(response['facetDistribution']['year']['1943']).to eq(1)
  end
end
