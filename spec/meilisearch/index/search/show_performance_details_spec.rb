# frozen_string_literal: true

RSpec.describe 'Meilisearch::Index - Search with performance details' do
  include_context 'search books with genre'

  it 'shows performance details when showPerformanceDetails is true' do
    response = index.search('hobbit', { show_performance_details: true })
    expect(response).to have_key('performanceDetails')
  end

  it 'hides performance details when showPerformanceDetails is false' do
    response = index.search('hobbit', { show_performance_details: false })
    expect(response).not_to have_key('performanceDetails')
  end

  it 'hides performance details when showPerformanceDetails is not set' do
    response = index.search('hobbit')
    expect(response).not_to have_key('performanceDetails')
  end
end
