# frozen_string_literal: true

RSpec.describe 'Meilisearch::Index - Search with showMatchesPosition' do
  include_context 'search books with genre'

  it 'does a custom search with showMatchesPosition' do
    response = index.search('the', show_matches_position: true)
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].first).to have_key('_matchesPosition')
    expect(response['hits'].first['_matchesPosition']).to have_key('title')
  end

  it 'does a placeholder search with showMatchesPosition' do
    response = index.search('', show_matches_position: true)
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].first).to have_key('_matchesPosition')
  end
end
