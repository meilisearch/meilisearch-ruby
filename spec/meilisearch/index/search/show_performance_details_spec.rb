# frozen_string_literal: true

RSpec.describe 'Meilisearch::Index - Search with performance details' do
  include_context 'search books with genre'

  it 'returns performance details when show_performance_details is true' do
    response = index.search('hobbit', { show_performance_details: true })
    expect(response).to have_key('performanceDetails')
  end

  it 'does not include performance details by default' do
    response = index.search('hobbit')
    expect(response).not_to have_key('performanceDetails')
  end
end
