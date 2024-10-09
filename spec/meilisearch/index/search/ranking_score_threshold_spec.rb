# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Search with rankingScoreThreshold' do
  include_context 'search books with genre'

  it 'does a custom search with rankingScoreThreshold' do
    response = index.search('harry potter and the prisoner of azkaban', { rankingScoreThreshold: 0.9 })
    expect(response['hits'].count).to be(0)

    response = index.search('harry potter and the', { rankingScoreThreshold: 0.3 })
    expect(response['hits'].count).to be(2)
  end
end
