# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Basic search' do
  include_context 'search books with genre'

  it 'does a basic search in index' do
    response = index.search('prince')
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits']).not_to be_empty
    expect(response['hits'].first).not_to have_key('_formatted')
  end

  it 'does a basic search with an empty query' do
    response = index.search('')
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(documents.count)
  end

  it 'does a basic search with a nil query' do
    response = index.search(nil)
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(documents.count)
    expect(response['hits'].first).not_to have_key('_formatted')
  end

  it 'does a basic search with an empty query and a custom ranking rule' do
    response = index.update_ranking_rules([
                                            'words',
                                            'typo',
                                            'sort',
                                            'proximity',
                                            'attribute',
                                            'exactness',
                                            'objectId:asc'
                                          ])
    index.wait_for_task(response['uid'])
    response = index.search('')
    expect(response['estimatedNbHits']).to eq(documents.count)
    expect(response['hits'].first['objectId']).to eq(1)
  end

  it 'does a basic search with an integer query' do
    response = index.search(1)
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(3)
    expect(response['hits'].first).not_to have_key('_formatted')
  end

  it 'does a phrase search' do
    response = index.search('coco "harry"')
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(1)
    expect(response['hits'].first['objectId']).to eq(4)
    expect(response['hits'].first).not_to have_key('_formatted')
  end
end
