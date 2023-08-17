# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Search with ranking score details' do
  include_context 'search books with genre'

  it 'experimental feature scoreDetails is not enabled so an error is raised' do
    enable_score_details(false)

    expect do
      index.search('hobbit', { show_ranking_score_details: true })
    end.to raise_error(MeiliSearch::ApiError)
  end

  it 'shows the ranking score details when showRankingScoreDetails is true' do
    enable_score_details(true)

    response = index.search('hobbit', { show_ranking_score_details: true })
    expect(response['hits'][0]).to have_key('_rankingScoreDetails')
  end

  it 'hides the ranking score details when showRankingScoreDetails is false' do
    enable_score_details(false)

    response = index.search('hobbit', { show_ranking_score_details: false })
    expect(response['hits'][0]).not_to have_key('_rankingScoreDetails')
  end

  it 'hides the ranking score details when showRankingScoreDetails is not set' do
    enable_score_details(false)

    response = index.search('hobbit')
    expect(response['hits'][0]).not_to have_key('_rankingScoreDetails')
  end
end
