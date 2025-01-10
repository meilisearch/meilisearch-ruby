# frozen_string_literal: true

RSpec.describe 'Meilisearch::Index - Basic search' do
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

  it 'has nbHits to maintain backward compatibility' do
    response = index.search('')

    expect(response).to be_a(Hash)
    expect(response).to have_key('nbHits')
    expect(response['nbHits']).to eq(response['estimatedTotalHits'])
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(documents.count)
    expect(response['hits'].first).not_to have_key('_formatted')
  end

  it 'does a basic search with an empty query and a custom ranking rule' do
    index.update_ranking_rules([
                                 'words',
                                 'typo',
                                 'sort',
                                 'proximity',
                                 'attribute',
                                 'exactness',
                                 'objectId:asc'
                               ]).await
    response = index.search('')
    expect(response['estimatedTotalHits']).to eq(documents.count)
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
    expect(response['hits'].count).to eq(2)
    expect(response['hits'].first['objectId']).to eq(4)
    expect(response['hits'].first).not_to have_key('_formatted')
  end

  context 'with finite pagination params' do
    it 'responds with specialized fields' do
      response = index.search('coco', { page: 2, hits_per_page: 2 })
      expect(response.keys).to contain_exactly(*FINITE_PAGINATED_SEARCH_RESPONSE_KEYS)

      response = index.search('coco', { page: 2, hitsPerPage: 2 })
      expect(response.keys).to contain_exactly(*FINITE_PAGINATED_SEARCH_RESPONSE_KEYS)
    end
  end

  context 'with attributes_to_search_on params' do
    it 'responds with empty attributes_to_search_on' do
      response = index.search('prince', { attributes_to_search_on: [] })
      expect(response).to be_a(Hash)
      expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
      expect(response['hits']).to be_empty
    end

    it 'responds with nil attributes_to_search_on' do
      response = index.search('prince', { attributes_to_search_on: nil })
      expect(response).to be_a(Hash)
      expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
      expect(response['hits']).not_to be_empty
    end

    it 'responds with title attributes_to_search_on' do
      response = index.search('prince', { attributes_to_search_on: ['title'] })
      expect(response).to be_a(Hash)
      expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
      expect(response['hits']).not_to be_empty
    end

    it 'responds with genre attributes_to_search_on' do
      response = index.search('prince', { attributes_to_search_on: ['genry'] })
      expect(response).to be_a(Hash)
      expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
      expect(response['hits']).to be_empty
    end

    it 'responds with nil attributes_to_search_on and empty query' do
      response = index.search('', { attributes_to_search_on: nil })
      expect(response).to be_a(Hash)
      expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
      expect(response['hits'].count).to eq(documents.count)
    end
  end
end
