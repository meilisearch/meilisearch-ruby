# frozen_string_literal: true

RSpec.describe MeiliSearch::Client::Keys do
  let(:client) { MeiliSearch::Client.new('http://localhost:8080', 'apiKey') }

  it 'has access to /keys' do
    expect(client.keys).to be_a(Array)
  end

  it 'creates key' do
    response = client.create_key(
      description: 'super key',
      acl: ['indexesRead'],
      indexes: ['*'],
      expiresAt: 1_627_571_698
    )

    expect(response).to have_key('key')
    expect(response).to have_key('createdAt')
  end

  it 'gets a specific key' do
    @key_data = client.keys.first
    response = client.key(@key_data['key'])
    expect(response).to be_a(Hash)
    expect(response).to have_key('description')
    expect(response).to have_key('acl')
    expect(response['acl']).to be_a(Array)
    expect(response).to have_key('indexes')
    expect(response['indexes']).to be_a(Array)
    expect(response).to have_key('revoked')
  end

  it 'deletes a specific key' do
    @key_data = client.keys.first
    response = client.delete_key(@key_data['key'])
    expect(response).to be_nil
  end
end
