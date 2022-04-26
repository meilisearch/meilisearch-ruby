# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - nested fields search' do
  include_context 'search books with nested fields'

  it 'searches without params' do
    response = index.search('an awesome')

    expect(response['hits'].count).to eq(1)
    expect(response.dig('hits', 0, 'info', 'comment')).to eq('An awesome book')
    expect(response.dig('hits', 0, 'info', 'reviewNb')).to eq(900)
  end

  it 'searches within index with searchableAttributes setting' do
    wait_for_it index.update_searchable_attributes(['title', 'info.comment'])
    wait_for_it index.add_documents(documents)

    response = index.search('An awesome')

    expect(response['hits'].count).to eq(1)
    expect(response.dig('hits', 0, 'info', 'comment')).to eq('An awesome book')
    expect(response.dig('hits', 0, 'info', 'reviewNb')).to eq(900)
  end

  it 'searches within index with searchableAttributes and sortableAttributes settings' do
    wait_for_it index.update_searchable_attributes(['title', 'info.comment'])
    wait_for_it index.update_sortable_attributes(['info.reviewNb'])
    wait_for_it index.add_documents(documents)

    response = index.search('An awesome')

    expect(response['hits'].count).to eq(1)
    expect(response.dig('hits', 0, 'info', 'comment')).to eq('An awesome book')
    expect(response.dig('hits', 0, 'info', 'reviewNb')).to eq(900)
  end
end
