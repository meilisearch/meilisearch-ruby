# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Multi-paramaters search' do
  include_context 'search books with genre'

  before do
    response = index.update_filterable_attributes(['genre'])
    index.wait_for_task(response['taskUid'])
  end

  it 'does a custom search with attributes to crop, filter and attributes to highlight' do
    response = index.search('prince',
                            {
                              attributesToCrop: ['title'],
                              cropLength: 2,
                              filter: 'genre = adventure',
                              attributesToHighlight: ['title']
                            })
    expect(response['hits'].count).to be(1)
    expect(response['hits'].first).to have_key('_formatted')
    expect(response['hits'].first['_formatted']['title']).to eq('…Petit <em>Prince</em>')
  end

  it 'does a custom search with attributesToRetrieve and a limit' do
    response = index.search('the', attributesToRetrieve: ['title', 'genre'], limit: 2)
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
    response = index.search('the', { limit: 1, attributesToHighlight: ['*'] })
    expect(response).to be_a(Hash)
    expect(response.keys).to contain_exactly(*DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['hits'].count).to eq(1)
    expect(response['hits'].first).to have_key('_formatted')
  end

  it 'does a custom search with filter, attributesToRetrieve and attributesToHighlight' do
    response = index.update_filterable_attributes(['genre'])
    index.wait_for_task(response['taskUid'])
    response = index.search('prinec',
                            {
                              filter: ['genre = fantasy'],
                              attributesToRetrieve: ['title'],
                              attributesToHighlight: ['*']
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
    response = index.update_filterable_attributes(['genre'])
    index.wait_for_task(response['taskUid'])
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

  context 'with snake_case options' do
    it 'does a custom search with attributes in a unusual formatting' do
      response = index.search(
        'prince',
        {
          aTTributes_TO_Crop: ['title'],
          cropLength: 2,
          filter: 'genre = adventure',
          attributes_to_highlight: ['title']
        }
      )

      expect(response['hits'].count).to be(1)
      expect(response['hits'].first).to have_key('_formatted')
      expect(response['hits'].first['_formatted']['title']).to eq('…Petit <em>Prince</em>')
    end
  end
end
