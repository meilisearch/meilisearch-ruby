# frozen_string_literal: true

RSpec.describe 'Meilisearch::Index - Facet search' do
  include_context 'search books with author, genre, year'

  before do
    response = index.update_filterable_attributes(['genre', 'year', 'author'])
    index.wait_for_task(response['taskUid'])
  end

  it 'requires facet name parameter' do
    expect { index.facet_search }.to raise_error ArgumentError
  end

  context 'without query parameter' do
    let(:results) { index.facet_search 'genre' }

    it 'returns all genres' do
      expect(results).to include(
        'facetHits' => a_collection_including(
          a_hash_including('value' => 'fantasy'),
          a_hash_including('value' => 'adventure'),
          a_hash_including('value' => 'romance')
        )
      )
    end

    it 'returns all genre counts' do
      expect(results).to include(
        'facetHits' => a_collection_including(
          a_hash_including('count' => 3),
          a_hash_including('count' => 3),
          a_hash_including('count' => 2)
        )
      )
    end

    it 'filters correctly' do
      results = index.facet_search 'genre', filter: 'year < 1940'

      expect(results['facetHits']).to contain_exactly(
        {
          'value' => 'adventure',
          'count' => 2
        },
        {
          'value' => 'romance',
          'count' => 2
        }
      )
    end
  end

  context 'with facet_query argument' do
    let(:results) { index.facet_search 'genre', 'fan' }

    it 'returns only matching genres' do
      expect(results).to include(
        'facetHits' => a_collection_containing_exactly(
          'value' => 'fantasy',
          'count' => 3
        )
      )
    end

    it 'filters correctly' do
      results = index.facet_search 'genre', 'fantasy', filter: 'year < 2006'

      expect(results['facetHits']).to contain_exactly(
        'value' => 'fantasy',
        'count' => 2
      )
    end
  end

  context 'with q parameter' do
    it 'applies matching_strategy "all"' do
      results = index.facet_search 'author', 'J. K. Rowling', q: 'Potter Stories', matching_strategy: 'all'

      expect(results['facetHits']).to be_empty
    end

    it 'applies matching_strategy "last"' do
      results = index.facet_search 'author', 'J. K. Rowling', q: 'Potter Stories', matching_strategy: 'last'

      expect(results).to include(
        'facetHits' => a_collection_containing_exactly(
          'value' => 'J. K. Rowling',
          'count' => 2
        )
      )
    end

    it 'applies filter parameter' do
      results = index.facet_search 'author', 'J. K. Rowling', q: 'Potter', filter: 'year < 2007'

      expect(results).to include(
        'facetHits' => a_collection_containing_exactly(
          'value' => 'J. K. Rowling',
          'count' => 1
        )
      )
    end

    it 'applies attributes_to_search_on parameter' do
      results = index.facet_search 'author', 'J. K. Rowling', q: 'Potter', attributes_to_search_on: ['year']

      expect(results['facetHits']).to be_empty
    end
  end
end
