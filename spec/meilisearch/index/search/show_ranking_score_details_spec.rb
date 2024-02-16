# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Search with ranking score details' do
  include_context 'search books with genre'

  it 'shows the ranking score details' do
    response = index.search('hobbit', { show_ranking_score_details: true })
    expect(response['hits'][0]).to have_key('_rankingScoreDetails')
  end

  it 'hides the ranking score details when showRankingScoreDetails is not set' do
    response = index.search('hobbit')
    expect(response['hits'][0]).not_to have_key('_rankingScoreDetails')
  end
end
