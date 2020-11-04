# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Health' do
  let(:client)       { MeiliSearch::Client.new($URL, $MASTER_KEY) }
  let(:wrong_client) { MeiliSearch::Client.new('bad_url') }

  it 'is healthy when the url is valid' do
    expect(client.healthy?).to be true
  end

  it 'is unhealthy when the url is invalid' do
    expect(wrong_client.healthy?).to be false
  end
end
