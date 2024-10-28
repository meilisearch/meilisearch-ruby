# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Search for similar documents' do
  let(:new_index) { client.index('similar_test_search') }

  before do
    client.create_index('similar_test_search').await
  end

  it 'requires document_id parameter' do
    expect { new_index.search_similar_documents }.to raise_error ArgumentError
  end

  it 'does a search for similar documents' do
    enable_vector_store(true)

    documents = [
      {
        title: 'Shazam!',
        release_year: 2019,
        id: '287947',
        _vectors: { 'manual' => [0.8, 0.4, -0.5] }
      },
      {
        title: 'Captain Marvel',
        release_year: 2019,
        id: '299537',
        _vectors: { 'manual' => [0.6, 0.8, -0.2] }
      },
      {
        title: 'How to Train Your Dragon: The Hidden World',
        release_year: 2019,
        id: '166428',
        _vectors: { 'manual' => [0.7, 0.7, -0.4] }
      }
    ]

    new_index.update_settings(
      embedders: {
        'manual' => {
          source: 'userProvided',
          dimensions: 3
        }
      }
    ).await

    new_index.add_documents(documents).await

    response = new_index.search_similar_documents('287947', embedder: 'manual')

    expect(response['hits']).not_to be_empty
    expect(response['estimatedTotalHits']).not_to be_nil
  end
end
