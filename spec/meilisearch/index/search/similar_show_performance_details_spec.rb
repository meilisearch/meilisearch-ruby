# frozen_string_literal: true

RSpec.describe 'Meilisearch::Index - Search similar documents with performance details' do
  let(:new_index) { client.index('similar_perf_test') }
  let(:documents) do
    [
      { id: '287947', title: 'Shazam!',        _vectors: { 'manual' => [0.8, 0.4, -0.5] } },
      { id: '299537', title: 'Captain Marvel', _vectors: { 'manual' => [0.6, 0.8, -0.2] } },
      { id: '166428', title: 'Dragon',         _vectors: { 'manual' => [0.7, 0.7, -0.4] } }
    ]
  end

  before do
    client.create_index('similar_perf_test').await
    new_index.update_settings(embedders: { 'manual' => { source: 'userProvided', dimensions: 3 } }).await
    new_index.add_documents(documents).await
  end

  it 'returns performance details when show_performance_details is true' do
    response = new_index.search_similar_documents('287947', embedder: 'manual', show_performance_details: true)
    expect(response).to have_key('performanceDetails')
  end

  it 'does not include performance details by default' do
    response = new_index.search_similar_documents('287947', embedder: 'manual')
    expect(response).not_to have_key('performanceDetails')
  end
end
