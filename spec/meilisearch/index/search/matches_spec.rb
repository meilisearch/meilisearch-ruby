# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Search with matches' do
  include_context 'search books with genre'

  it 'does a custom search with matches' do
    response = index.search('the', matches: true)
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].first).to have_key('_matchesInfo')
    expect(response['hits'].first['_matchesInfo']).to have_key('title')
  end

  it 'does a placeholder search with matches' do
    response = index.search('', matches: true)
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].first).to have_key('_matchesInfo')
  end
end
