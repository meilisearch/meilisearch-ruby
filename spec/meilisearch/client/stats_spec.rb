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

  it 'gets stats with human-readable size format' do
    response = client.stats(size_format: 'human')
    expect(response).to have_key('databaseSize')
    expect(response['databaseSize']).to be_a(String)
  end

  it 'gets stats with internal database sizes' do
    client.create_index('books').await
    response = client.stats(show_internal_database_sizes: true)

    expect(response).to have_key('indexes')
    response['indexes'].each_value do |index_stats|
      expect(index_stats).to have_key('internalDatabaseSizes')
    end
  end
end
