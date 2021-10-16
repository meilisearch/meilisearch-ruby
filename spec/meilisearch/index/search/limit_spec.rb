# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Search with limit' do
  include_context 'search books with genre'

  it 'does a custom search with limit' do
    response = index.search('the', limit: 1)
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['limit']).to be(1)
    expect(response['hits'].count).to eq(1)
    expect(response['hits'].first).not_to have_key('_formatted')
  end

  it 'does a placeholder search with limit' do
    response = index.search('', limit: 2)
    expect(response['limit']).to be(2)
    expect(response['hits'].count).to be(2)
    expect(response['hits'].first).not_to have_key('_formatted')
  end

  it 'does a placeholder search with bigger limit than the nb of docs' do
    response = index.search('', limit: 20)
    expect(response['hits'].count).to be(documents.count)
    expect(response['limit']).to be(20)
    expect(response['hits'].first).not_to have_key('_formatted')
  end
end
