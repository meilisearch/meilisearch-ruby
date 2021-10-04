# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Search with highlight' do
  include_context 'search books with genre'

  it 'does a custom search with highlight' do
    response = index.search('the', attributesToHighlight: ['title'])
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(3)
    expect(response['hits'].first).to have_key('_formatted')
    expect(response['hits'].first['_formatted']['title']).to eq('<em>The</em> Hobbit')
  end

  it 'does a placeholder search with attributes to highlight' do
    response = index.search('', attributesToHighlight: ['*'])
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(7)
    expect(response['hits'].first).to have_key('_formatted')
  end

  it 'does a placeholder search (nil) with attributes to highlight' do
    response = index.search(nil, attributesToHighlight: ['*'])
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(documents.count)
    expect(response['hits'].first).to have_key('_formatted')
  end
end
