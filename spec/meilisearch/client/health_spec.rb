# frozen_string_literal: true

require './lib/meilisearch/client'

RSpec.describe MeiliSearch::Client::Health do
  let(:client) { MeiliSearch::Client.new('http://localhost:8080', 'apiKey') }

  it 'is healthy' do
    expect(client.is_healthy?).to be true
  end

  it 'sets unhealthy' do
    client.update_health(false)
    expect(client.is_healthy?).to be false
    client.update_health(true)
  end
end
