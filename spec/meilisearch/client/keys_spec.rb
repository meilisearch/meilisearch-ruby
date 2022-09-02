# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Keys' do
  context 'When managing keys' do
    let(:uuid_v4) { 'c483e150-cff1-4a45-ac26-bb8eb8e01d36' }
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

    it 'creates a key' do
      new_key = client.create_key(add_docs_key_options)

      expect(new_key['expiresAt']).to be_nil
      expect(new_key['key']).to be_a(String)
      expect(new_key['createdAt']).to be_a(String)
      expect(new_key['updatedAt']).to be_a(String)
      expect(new_key['indexes']).to eq(['*'])
      expect(new_key['description']).to eq('A new key to add docs')
    end

    it 'creates a key with wildcarded action' do
      new_key = client.create_key(add_docs_key_options.merge(actions: ['documents.*']))

      expect(new_key['actions']).to eq(['documents.*'])
    end

    it 'creates a key with setting uid' do
      new_key = client.create_key(add_docs_key_options.merge(uid: uuid_v4))

      expect(new_key['expiresAt']).to be_nil
      expect(new_key['name']).to be_nil
      expect(new_key['uid']).to eq(uuid_v4)
      expect(new_key['key']).to be_a(String)
      expect(new_key['createdAt']).to be_a(String)
      expect(new_key['updatedAt']).to be_a(String)
      expect(new_key['indexes']).to eq(['*'])
      expect(new_key['description']).to eq('A new key to add docs')
    end

    it 'gets a key with their key data' do
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

    it 'retrieves a list of keys' do
      new_key = client.create_key(add_docs_key_options)

      list = client.keys

      expect(list.keys).to contain_exactly('limit', 'offset', 'results', 'total')
      expect(list['results']).to eq([new_key])
      expect(list['total']).to eq(1)
    end

    it 'paginates keys list with limit/offset' do
      client.create_key(add_docs_key_options)

      expect(client.keys(limit: 0, offset: 20)['results']).to be_empty
      expect(client.keys(limit: 5, offset: 199)['results']).to be_empty
    end

    it 'gets a key with their uid' do
      new_key = client.create_key(delete_docs_key_options.merge(uid: uuid_v4))

      key = client.key(uuid_v4)

      expect(key).to eq(new_key)
    end

    it 'updates a key with their key data' do
      new_key = client.create_key(delete_docs_key_options)
      new_updated_key = client.update_key(new_key['key'], indexes: ['coco'], description: 'no coco')

      expect(new_updated_key['key']).to eq(new_key['key'])
      expect(new_updated_key['description']).to eq('no coco')
      # remain untouched since v0.28.0 Meilisearch just support updating name/description.
      expect(new_updated_key['indexes']).to eq(['*'])
    end

    it 'updates a key with their uid data' do
      client.create_key(delete_docs_key_options.merge(uid: uuid_v4))
      new_updated_key = client.update_key(uuid_v4, name: 'coco')

      expect(new_updated_key['name']).to eq('coco')
    end

    it 'deletes a key' do
      new_key = client.create_key(add_docs_key_options)
      client.delete_key(new_key['key'])

      expect do
        client.key(new_key['key'])
      end.to raise_error(MeiliSearch::ApiError)
    end
  end
end
