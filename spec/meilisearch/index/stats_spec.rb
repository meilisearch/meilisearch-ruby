# frozen_string_literal: true

RSpec.describe 'Meilisearch::Index - Stats' do
  include_context 'search books with genre'

  it 'returns stats of the index' do
    response = index.stats
    expect(response).to be_a(Hash)
    expect(response).not_to be_empty
  end

  it 'returns stats with human-readable size format' do
    response = index.stats(size_format: 'human')
    expect(response).to have_key('rawDocumentDbSize')
    expect(response['rawDocumentDbSize']).to be_a(String)
  end

  it 'returns stats with internal database sizes' do
    response = index.stats(show_internal_database_sizes: true)
    expect(response).to have_key('internalDatabaseSizes')
    expect(response['internalDatabaseSizes']).to be_a(Hash)
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
