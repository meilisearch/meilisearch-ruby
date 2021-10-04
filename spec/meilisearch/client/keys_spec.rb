# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Keys' do
  it 'gets the list of keys' do
    response = test_client.keys
    expect(response).to be_a(Hash)
    expect(response.count).to eq(2)
    expect(response.keys).to contain_exactly('private', 'public')
    expect(response['private']).to be_a(String)
    expect(response['public']).to be_a(String)
  end

  it 'fails to get settings if public key used' do
    public_key = test_client.keys['public']
    new_client = MeiliSearch::Client.new(URL, public_key)
    expect do
      new_client.index(test_uid).settings
    end.to raise_meilisearch_api_error_with(403, 'invalid_token', 'authentication_error')
  end

  it 'fails to get keys if private key used' do
    private_key = test_client.keys['private']
    new_client = MeiliSearch::Client.new(URL, private_key)
    expect do
      new_client.keys
    end.to raise_meilisearch_api_error_with(403, 'invalid_token', 'authentication_error')
  end

  it 'fails to search if no key used' do
    new_client = MeiliSearch::Client.new(URL)
    expect do
      new_client.index(test_uid).settings
    end.to raise_meilisearch_api_error_with(401, 'missing_authorization_header', 'authentication_error')
  end

  it 'succeeds to search when using public key' do
    public_key = test_client.keys['public']
    response = test_index.add_documents(title: 'Test')
    test_index.wait_for_pending_update(response['updateId'])

    new_client = MeiliSearch::Client.new(URL, public_key)
    response = new_client.index(test_uid).search('test')
    expect(response).to have_key('hits')
  end

  it 'succeeds to get settings when using private key' do
    private_key = test_client.keys['private']
    new_client = MeiliSearch::Client.new(URL, private_key)
    response = new_client.index(test_uid).settings
    expect(response).to have_key('rankingRules')
  end

  it 'works with method aliases' do
    expect(test_client.method(:keys) == test_client.method(:get_keys)).to be_truthy
  end
end
