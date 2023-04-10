# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Multiple Index Search' do
  before do
    client.create_index('books')
    task = client.create_index('movies')
    client.wait_for_task(task['taskUid'])
  end

  it 'does a custom search with two different indexes' do
    response = client.multi_search([
                                     { index_uid: 'books', q: 'prince' },
                                     { index_uid: 'movies', q: 'prince' }
                                   ])

    expect(response['results'].count).to eq(2)
    expect(response['results'][0]['estimatedTotalHits']).to eq(0)
    expect(response['results'][1]['estimatedTotalHits']).to eq(0)
  end
end
