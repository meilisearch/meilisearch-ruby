# frozen_string_literal: true

RSpec.describe 'Meilisearch::Client - Stats' do
  it 'gets version' do
    response = client.version
    expect(response).to be_a(Hash)
    expect(response).to have_key('commitSha')
    expect(response).to have_key('commitDate')
    expect(response).to have_key('pkgVersion')
  end

  it 'gets stats' do
    response = client.stats
    expect(response).to have_key('databaseSize')
  end

  context 'with an index' do
    include_context 'search books with genre'

    it 'gets index sizes' do
      index_stats = client.stats.fetch('indexes').fetch(index.uid)
      expect(index_stats).to include(
        'indexSize' => be_a(Integer),
        'usedIndexSize' => be_a(Integer)
      )
    end

    it 'formats index sizes' do
      index_stats = client.stats(size_format: :human).fetch('indexes').fetch(index.uid)
      expect(index_stats).to include(
        'indexSize' => be_a(String),
        'usedIndexSize' => be_a(String)
      )
    end
  end
end
