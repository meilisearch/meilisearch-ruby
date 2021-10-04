# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Sorted search' do
  include_context 'search books with author, genre, year'
  before do
    response = index.update_sortable_attributes(['year', 'author'])
    index.wait_for_pending_update(response['updateId'])

    response = index.update_ranking_rules([
                                            'sort',
                                            'words',
                                            'typo',
                                            'proximity',
                                            'attribute',
                                            'exactness'
                                          ])
    index.wait_for_pending_update(response['updateId'])
  end

  it 'does a custom search with one sort' do
    response = index.search('prince', { sort: ['year:desc'] })
    expect(response['hits'].count).to eq(2)
    expect(response['hits'].first['objectId']).to eq(4)
  end

  it 'does a custom search by sorting on strings' do
    response = index.search('prince', { sort: ['author:asc'] })
    expect(response['hits'].count).to eq(2)
    expect(response['hits'].first['objectId']).to eq(456)
  end

  it 'does a custom search with multiple sort' do
    response = index.search('pr', { sort: ['year:desc', 'author:asc'] })
    expect(response['hits'].count).to eq(3)
    expect(response['hits'].first['objectId']).to eq(4)
  end

  it 'does a placeholder search with multiple sort' do
    response = index.search('', { sort: ['year:desc', 'author:asc'] })
    expect(response['hits'].count).to eq(documents.count)
    expect(response['hits'].first['objectId']).to eq(2056)
  end
end
