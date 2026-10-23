# frozen_string_literal: true

RSpec.describe 'Meilisearch::Client - Multi-search with performance details' do
  include_context 'search books with genre'

  it 'returns performance details per query when show_performance_details is true' do
    response = client.multi_search(queries: [
                                     { index_uid: index.uid, q: 'hobbit', show_performance_details: true }
                                   ])
    expect(response['results'][0]).to have_key('performanceDetails')
  end

  it 'does not include performance details by default' do
    response = client.multi_search(queries: [
                                     { index_uid: index.uid, q: 'hobbit' }
                                   ])
    expect(response['results'][0]).not_to have_key('performanceDetails')
  end
end
