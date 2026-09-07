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
    stats_index = client.index('stats_index')
    stats_index.add_documents([{ id: 1 }]).await

    response = client.stats
    expect(response).to have_key('databaseSize')
    expect(response.dig('indexes', stats_index.uid)).to include(
      'indexSize' => be_a(Integer),
      'usedIndexSize' => be_a(Integer)
    )
  end

  it 'forwards the requested size format for nested index stats' do
    stats_index = client.index('stats_human_index')
    stats_index.add_documents([{ id: 1 }]).await

    response = client.stats(size_format: 'human')
    expect(response).to have_key('databaseSize')
    expect(response.dig('indexes', stats_index.uid, 'indexSize')).to be_a(String)
    expect(response.dig('indexes', stats_index.uid, 'usedIndexSize')).to be_a(String)
  end
end
