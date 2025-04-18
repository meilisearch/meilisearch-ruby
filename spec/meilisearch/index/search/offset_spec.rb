# frozen_string_literal: true

RSpec.describe 'Meilisearch::Index - Search with offset' do
  include_context 'search books with genre'

  it 'does a custom search with an offset set to 1' do
    response = index.search('prince')
    response_with_offset = index.search('prince', offset: 1)
    expect(response['hits'][1]).to eq(response_with_offset['hits'][0])
  end

  it 'does a placeholder search with an offset set to 3' do
    response = index.search('')
    response_with_offset = index.search('', offset: 3)
    expect(response['hits'][3]).to eq(response_with_offset['hits'][0])
  end

  it 'does a placeholder search with an offset set to 3 and custom ranking rules' do
    index.update_ranking_rules(['objectId:asc']).await
    response = index.search('')
    response_with_offset = index.search('', offset: 3)
    expect(response['hits'].first['objectId']).to eq(1)
    expect(response['hits'][3]).to eq(response_with_offset['hits'][0])
    expect(response['hits'].last['objectId']).to eq(1344)
    expect(response_with_offset['hits'].last['objectId']).to eq(1344)
  end
end
