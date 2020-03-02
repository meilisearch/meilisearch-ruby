# frozen_string_literal: true

RSpec.describe MeiliSearch::Client::Keys do
  before(:all) do
    @client = MeiliSearch::Client.new($URL, $MASTER_KEY)
    @uid = 'uid'
    @client.create_index(@uid)
  end

  it 'gets the list of keys' do
    response = @client.keys
    expect(response).to be_a(Hash)
    expect(response.count).to eq(2)
    expect(response.keys).to contain_exactly('private', 'public')
    expect(response['private']).to be_a(String)
    expect(response['public']).to be_a(String)
  end

  it 'fails to get settings if public key used' do
    public_key = @client.keys['public']
    new_client = MeiliSearch::Client.new($URL, public_key)
    expect { new_client.index(@uid).settings }.to raise_meilisearch_http_error_with(403)
  end

  it 'fails to get keys if private key used' do
    private_key = @client.keys['private']
    new_client = MeiliSearch::Client.new($URL, private_key)
    expect { new_client.keys }.to raise_meilisearch_http_error_with(403)
  end

  it 'fails to search if no key used' do
    new_client = MeiliSearch::Client.new($URL)
    expect { new_client.index(@uid).settings }.to raise_meilisearch_http_error_with(403)
  end

  it 'succeeds to search when using public key' do
    public_key = @client.keys['public']
    new_client = MeiliSearch::Client.new($URL, public_key)
    response = new_client.index(@uid).search('test')
    expect(response).to have_key('hits')
  end

  it 'succeeds to get settings when using private key' do
    private_key = @client.keys['private']
    new_client = MeiliSearch::Client.new($URL, private_key)
    response = new_client.index(@uid).settings
    expect(response).to have_key('rankingRules')
  end

  it 'works with method aliases' do
    expect(@client.method(:keys) == @client.method(:get_keys)).to be_truthy
  end
end
