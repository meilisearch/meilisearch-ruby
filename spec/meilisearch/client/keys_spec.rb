# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Keys' do
  context 'When a client uses default key roles' do
    let(:search_key) { client.keys['results'].find { |k| k['description'].start_with? 'Default Search' } }
    let(:admin_key) { client.keys['results'].find { |k| k['description'].start_with? 'Default Admin' } }

    it 'fails to get settings if public key used' do
      new_client = MeiliSearch::Client.new(URL, search_key['key'])

      expect do
        new_client.index(random_uid).settings
      end.to raise_meilisearch_api_error_with(403, 'invalid_api_key', 'auth')
    end

    it 'fails to get keys if private key used' do
      new_client = MeiliSearch::Client.new(URL, admin_key['key'])

      expect do
        new_client.keys
      end.to raise_meilisearch_api_error_with(403, 'invalid_api_key', 'auth')
    end

    it 'fails to get settings if no key is used' do
      new_client = MeiliSearch::Client.new(URL)

      expect do
        new_client.index(random_uid).settings
      end.to raise_meilisearch_api_error_with(401, 'missing_authorization_header', 'auth')
    end

    it 'succeeds to search when using public key' do
      uid = random_uid
      index = client.index(uid)
      index.add_documents!(title: 'Test')
      new_client = MeiliSearch::Client.new(URL, search_key['key'])
      response = new_client.index(uid).search('test')

      expect(response).to have_key('hits')
    end

    it 'succeeds to get settings when using private key' do
      uid = random_uid
      client.create_index!(uid)
      new_client = MeiliSearch::Client.new(URL, admin_key['key'])
      response = new_client.index(uid).settings

      expect(response).to have_key('rankingRules')
    end
  end

  context 'When managing keys' do
    let(:delete_docs_key_options) do
      {
        description: 'A new key to delete docs',
        actions: ['documents.delete'],
        indexes: ['*'],
        expiresAt: nil
      }
    end
    let(:add_docs_key_options) do
      {
        description: 'A new key to add docs',
        actions: ['documents.add'],
        indexes: ['*'],
        expiresAt: nil
      }
    end

    it 'gets the list of the default keys' do
      results = client.keys['results']

      expect(results).to be_a(Array)
      expect(results.count).to be >= 2
    end

    it 'creates a key' do
      new_key = client.create_key(add_docs_key_options)

      expect(new_key['expiresAt']).to be_nil
      expect(new_key['key']).to be_a(String)
      expect(new_key['createdAt']).to be_a(String)
      expect(new_key['updatedAt']).to be_a(String)
      expect(new_key['indexes']).to eq(['*'])
      expect(new_key['description']).to eq('A new key to add docs')
    end

    it 'creates a key using snake_case' do
      new_key = client.create_key(add_docs_key_options)

      expect(new_key['expiresAt']).to be_nil
      expect(new_key['key']).to be_a(String)
      expect(new_key['createdAt']).to be_a(String)
      expect(new_key['updatedAt']).to be_a(String)
      expect(new_key['indexes']).to eq(['*'])
      expect(new_key['description']).to eq('A new key to add docs')
    end

    it 'gets a key' do
      new_key = client.create_key(delete_docs_key_options)

      expect(client.key(new_key['key'])['description']).to eq('A new key to delete docs')

      key = client.key(new_key['key'])

      expect(key['expiresAt']).to be_nil
      expect(key['key']).to be_a(String)
      expect(key['createdAt']).to be_a(String)
      expect(key['updatedAt']).to be_a(String)
      expect(key['indexes']).to eq(['*'])
      expect(key['description']).to eq('A new key to delete docs')
    end

    it 'updates a key' do
      new_key = client.create_key(delete_docs_key_options)
      new_updated_key = client.update_key(new_key['key'], indexes: ['coco'])

      expect(new_updated_key['key']).to eq(new_key['key'])
      expect(new_updated_key['description']).to eq(new_key['description'])
      expect(new_updated_key['indexes']).to eq(['coco'])
    end

    it 'updates a key using snake_case' do
      new_key = client.create_key(delete_docs_key_options)
      new_updated_key = client.update_key(new_key['key'], indexes: ['coco'])

      expect(new_updated_key['key']).to eq(new_key['key'])
      expect(new_updated_key['description']).to eq(new_key['description'])
      expect(new_updated_key['indexes']).to eq(['coco'])
    end

    it 'deletes a key' do
      new_key = client.create_key(add_docs_key_options)
      client.delete_key(new_key['key'])

      expect(client.keys.filter { |k| k['key'] == new_key['key'] }).to be_empty
    end
  end
end
