# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Vector search' do
  it 'does a basic search' do
    enable_vector_store(true)

    documents = [
      { objectId: 0, _vectors: [0, 0.8, -0.2], title: 'Across The Universe' },
      { objectId: 1, _vectors: [1, -0.2, 0], title: 'All Things Must Pass' },
      { objectId: 2, _vectors: [0.5, 3, 1], title: 'And Your Bird Can Sing' }
    ]

    client.create_index('vector_test_search').await
    new_index = client.index('vector_test_search')
    new_index.add_documents(documents).await

    expect(new_index.search(vector: [9, 9, 9])['hits']).to be_empty
    expect(new_index.search('All Things Must Pass')['hits']).not_to be_empty
  end
end
