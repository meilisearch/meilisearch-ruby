# frozen_string_literal: true

RSpec.describe MeiliSearch::Client::Keys do

  before(:all) do
    @client = MeiliSearch::Client.new($URL, $API_KEY)
    clear_all_keys(@client)
    @keys = []
  end

  let(:options) do
    {
      description: 'super key',
      acl: ['indexesRead'],
      indexes: ['*'],
      expiresAt: 1_627_571_698
    }
  end

  it 'creates key' do
    response = @client.create_key(options)
    @keys << response['key']
    expect(response['key']).to be_a(String)
    expect(response['description']).to eq(options[:description])
    expect(response).to have_key('acl')
    expect(response).to have_key('createdAt')
  end

  it 'gets a list of keys' do
    response = @client.keys
    expect(response).to be_a(Array)
    expect(response.count).to eq(1)
    expect(response.first['key']).to eq(@keys.first)
    expect(response.first['description']).to eq(options[:description])
  end

  it 'gets a specific key' do
    response = @client.key(@keys.first)
    expect(response).to be_a(Hash)
    expect(response).to have_key('key')
    expect(response['key']).to eq(@keys.first)
    expect(response).to have_key('description')
    expect(response['description']).to eq(options[:description])
    expect(response).to have_key('acl')
    expect(response['acl']).to be_a(Array)
    expect(response).to have_key('indexes')
    expect(response['indexes']).to be_a(Array)
    expect(response).to have_key('revoked')
  end

  it 'update a key' do
    new_description = 'new description'
    response = @client.update_key(@keys.first, description: new_description)
    expect(response).to be_a(Hash)
    expect(response['key']).to eq(@keys.first)
    expect(response['description']).to eq(new_description)
    fetched_key = @client.key(@keys.first)
    expect(fetched_key['description']).to eq(new_description)
  end

  it 'deletes a specific key' do
    response = @client.delete_key(@keys.first)
    expect(response).to be_nil
  end
end
