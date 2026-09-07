# frozen_string_literal: true

RSpec.describe 'Meilisearch::Index - Stats' do
  include_context 'search books with genre'

  it 'returns stats of the index' do
    response = index.stats
    expect(response).to be_a(Hash)
    expect(response).not_to be_empty
    expect(response).to include(
      'indexSize' => be_a(Integer),
      'usedIndexSize' => be_a(Integer)
    )
  end

  it 'forwards the requested size format' do
    response = index.stats(size_format: 'human')
    expect(response['indexSize']).to be_a(String)
    expect(response['usedIndexSize']).to be_a(String)
  end

  it 'gets the number of documents' do
    response = index.number_of_documents
    expect(response).to eq(documents.count)
  end

  it 'gets the distribution of fields' do
    response = index.field_distribution
    expect(response).to be_a(Hash)
  end

  it 'knows when it is indexing' do
    expect(index.indexing?).to be_falsy
  end
end
