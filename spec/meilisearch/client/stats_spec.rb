# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Stats' do
  before(:all) do
    @client = MeiliSearch::Client.new($URL, $MASTER_KEY)
  end

  it 'gets version' do
    response = @client.version
    expect(response).to be_a(Hash)
    expect(response).to have_key('commitSha')
    expect(response).to have_key('buildDate')
    expect(response).to have_key('pkgVersion')
  end

  it 'gets stats' do
    response = @client.stats
    expect(response).to have_key('databaseSize')
  end
end
