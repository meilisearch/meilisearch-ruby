# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Keys' do
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
      new_updated_key = client.update_key(new_key['key'], indexes: ['coco'], description: 'no coco')

      expect(new_updated_key['key']).to eq(new_key['key'])
      expect(new_updated_key['description']).to eq('no coco')
      # remain untouched since v0.28.0 Meilisearch just support updating name/description.
      expect(new_updated_key['indexes']).to eq(['*'])
    end

    it 'updates a key using snake_case' do
      new_key = client.create_key(delete_docs_key_options)
      new_updated_key = client.update_key(new_key['key'], indexes: ['coco'])

      expect(new_updated_key['key']).to eq(new_key['key'])
      expect(new_updated_key['description']).to eq(new_key['description'])
      expect(new_updated_key['indexes']).to eq(['*'])
    end

    it 'deletes a key' do
      new_key = client.create_key(add_docs_key_options)
      client.delete_key(new_key['key'])

      expect(client.keys.filter { |k| k['key'] == new_key['key'] }).to be_empty
    end
  end
end
