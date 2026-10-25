# frozen_string_literal: true

RSpec.describe 'Meilisearch::Index - Search with inline rule' do
  include_context 'search books with genre'

  let(:metadata_client) do
    Meilisearch::Client.new(URL, MASTER_KEY, timeout: 2, max_retries: 1,
                                             custom_headers: { 'Meili-Include-Metadata' => true })
  end
  let(:pin_hitchhiker) do
    {
      uid: 'pin-hitchhiker',
      conditions: { query: { words: 'prince' } },
      actions: { pin: [{ id: '42', position: 0 }] }
    }
  end

  before { enable_dynamic_search_rules(true) }
  after { enable_dynamic_search_rules(false) }

  it 'applies the inline rule to the search' do
    response = index.search('prince', inline_rule: pin_hitchhiker)

    expect(response['hits'].first['objectId']).to eq(42)
    expect(response).not_to have_key('metadata')
  end

  it 'returns the condition outcomes when metadata is requested' do
    response = metadata_client.index('books').search('hobbit', inline_rule: pin_hitchhiker)

    expect(response['hits'].first['objectId']).to eq(1344)
    expect(response['metadata']['inlineRuleConditionOutcomes']).to include(
      'satisfiesQueryWordsCondition' => { 'missingWord' => { 'word' => 'prince' } }
    )
  end

  it 'applies the inline rule to a multi-search query only' do
    response = metadata_client.multi_search(queries: [
                                              { index_uid: 'books', q: 'prince' },
                                              { index_uid: 'books', q: 'prince', inline_rule: pin_hitchhiker }
                                            ])

    plain, ruled = response['results']
    expect(plain['hits'].first['objectId']).not_to eq(42)
    expect(plain['metadata']).not_to have_key('inlineRuleConditionOutcomes')
    expect(ruled['hits'].first['objectId']).to eq(42)
    expect(ruled['metadata']['inlineRuleConditionOutcomes']).to include(
      'satisfiesQueryWordsCondition' => 'satisfied'
    )
  end
end
