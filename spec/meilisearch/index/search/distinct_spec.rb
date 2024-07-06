# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Distinct search' do
  include_context 'search books with genre'

  before do
    index.update_filterable_attributes(['genre']).await
  end

  it 'does a search without distinct' do
    response = index.search('harry potter')
    expect(response['hits'].count).to eq(2)
  end

  it 'does a custom search with distinct' do
    response = index.search('harry potter', { distinct: 'genre' })
    expect(response['hits'].count).to eq(1)
  end
end
