# frozen_string_literal: true

RSpec.describe MeiliSearch::Client::Health do
  let(:client)       { MeiliSearch::Client.new($URL, $API_KEY) }
  let(:wrong_client) { MeiliSearch::Client.new('nope') }

  it 'is healthy when the url is valid' do
    expect(client.is_healthy?).to be true
  end

  it 'is unhealthy when the url is invalid' do
    expect(wrong_client.is_healthy?).to be false
  end

  it 'sets unhealthy' do
    client.update_health(false)
    expect(client.is_healthy?).to be false
    client.update_health(true)
  end
end
