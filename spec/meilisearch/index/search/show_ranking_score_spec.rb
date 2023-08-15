# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Search with ranking score' do
  include_context 'search books with genre'

  it 'shows the ranking score when showRankingScore is true' do
    response = index.search('hobbit', { show_ranking_score: true })
    expect(response['hits'][0]).to have_key('_rankingScore')
  end

  it 'hides the ranking score when showRankingScore is false' do
    response = index.search('hobbit', { showRankingScore: false })
    expect(response['hits'][0]).not_to have_key('_rankingScore')
  end

  it 'hides the ranking score when showRankingScore is not set' do
    response = index.search('hobbit')
    expect(response['hits'][0]).not_to have_key('_rankingScore')
  end
end
