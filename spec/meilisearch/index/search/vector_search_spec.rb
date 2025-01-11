# frozen_string_literal: true

RSpec.describe 'Meilisearch::Index - Vector search' do
  it 'does a basic search' do
    client.update_experimental_features(vector_store: true)

    documents = [
      { objectId: 0, _vectors: { custom: [0, 0.8, -0.2] }, title: 'Across The Universe' },
      { objectId: 1, _vectors: { custom: [1, -0.2, 0] }, title: 'All Things Must Pass' },
      { objectId: 2, _vectors: { custom: [0.5, 3, 1] }, title: 'And Your Bird Can Sing' }
    ]
    settings = {
      embedders: {
        custom: {
          source: 'userProvided',
          dimensions: 3
        }
      }
    }

    client.create_index('vector_test_search').await
    new_index = client.index('vector_test_search')
    new_index.update_settings(settings).await
    new_index.add_documents(documents).await

    expect(new_index.search('',
                            { vector: [9, 9, 9],
                              hybrid: { embedder: 'custom', semanticRatio: 1.0 } })['hits']).not_to be_empty
    expect(new_index.search('',
                            { vector: [9, 9, 9],
                              hybrid: { embedder: 'custom', semanticRatio: 1.0 } })['semanticHitCount']).to be 3
    expect(new_index.search('All Things Must Pass',
                            { vector: [9, 9, 9],
                              hybrid: { embedder: 'custom', semanticRatio: 0.1 } })['semanticHitCount']).to be 2
    expect(new_index.search('All Things Must Pass')['hits']).not_to be_empty
  end
end
