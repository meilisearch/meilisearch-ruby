# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Search with facetsDistribution' do
  include_context 'search books with author, genre, year'

  before do
    response = index.update_filterable_attributes(['genre', 'year', 'author'])
    index.wait_for_pending_update(response['updateId'])
  end

  it 'does a custom search with facetsDistribution' do
    response = index.search('prinec', facetsDistribution: ['genre', 'author'])
    expect(response.keys).to contain_exactly(
      *DEFAULT_SEARCH_RESPONSE_KEYS,
      'facetsDistribution',
      'exhaustiveFacetsCount'
    )
    expect(response['exhaustiveFacetsCount']).to be false
    expect(response['nbHits']).to eq(2)
    expect(response['facetsDistribution'].keys).to contain_exactly('genre', 'author')
    expect(response['facetsDistribution']['genre'].keys).to contain_exactly('adventure', 'fantasy')
    expect(response['facetsDistribution']['genre']['adventure']).to eq(1)
    expect(response['facetsDistribution']['genre']['fantasy']).to eq(1)
    expect(response['facetsDistribution']['author']['J. K. Rowling']).to eq(1)
    expect(response['facetsDistribution']['author']['Antoine de Saint-Exupéry']).to eq(1)
  end

  it 'does a placeholder search with facetsDistribution' do
    response = index.search('', facetsDistribution: ['genre', 'author'])
    expect(response.keys).to contain_exactly(
      *DEFAULT_SEARCH_RESPONSE_KEYS,
      'facetsDistribution',
      'exhaustiveFacetsCount'
    )
    expect(response['exhaustiveFacetsCount']).to be false
    expect(response['nbHits']).to eq(documents.count)
    expect(response['facetsDistribution'].keys).to contain_exactly('genre', 'author')
    expect(response['facetsDistribution']['genre'].keys).to contain_exactly('romance', 'adventure', 'fantasy')
    expect(response['facetsDistribution']['genre']['romance']).to eq(2)
    expect(response['facetsDistribution']['genre']['adventure']).to eq(3)
    expect(response['facetsDistribution']['genre']['fantasy']).to eq(3)
    expect(response['facetsDistribution']['author']['J. K. Rowling']).to eq(2)
  end

  it 'does a placeholder search with facetsDistribution on number' do
    response = index.search('', facetsDistribution: ['year'])
    expect(response.keys).to contain_exactly(
      *DEFAULT_SEARCH_RESPONSE_KEYS,
      'facetsDistribution',
      'exhaustiveFacetsCount'
    )
    expect(response['exhaustiveFacetsCount']).to be false
    expect(response['nbHits']).to eq(documents.count)
    expect(response['facetsDistribution'].keys).to contain_exactly('year')
    expect(response['facetsDistribution']['year'].keys).to contain_exactly(*documents.map { |o| o[:year].to_s })
    expect(response['facetsDistribution']['year']['1943']).to eq(1)
  end
end
