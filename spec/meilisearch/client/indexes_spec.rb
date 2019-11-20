# frozen_string_literal: true

require './lib/meilisearch/client'

RSpec.describe MeiliSearch::Client::Indexes do
  before(:all) do
    @client = MeiliSearch::Client.new('http://localhost:8080', 'apiKey')
    @index_name1 = SecureRandom.hex(4)
    @index_name2 = SecureRandom.hex(4)
  end

  let(:client) { @client }
  let(:name1)  { @index_name1 }
  let(:name2)  { @index_name2 }
  let(:schema) do
    {
      objectId: [:displayed, :indexed, :identifier],
      title: [:displayed, :indexed]
    }
  end

  it 'creates an index without schema' do
    response = client.create_index(name1)
    expect(response).to be_nil
  end

  it 'creates an index with schema' do
    response = client.create_index(
      name2,
      schema
    )
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
  end

  it 'gets list of indexes' do
    response = client.indexes
    expect(response).to be_a(Array)
    expect(response.count).to be >= 2
  end

  it 'has schema of specified index' do
    response = client.index(name2)
    expect(response).to be_a(Hash)
    expect(response).to have_key('objectId')
    expect(response).to have_key('title')
  end

  it 'updates schema of index' do
    new_schema = {
      objectId: [:indexed, :identifier],
      title: [:displayed, :indexed]
    }
    response = client.update_index(name2, new_schema)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
  end

  it 'deletes index' do
    client.delete_index(name1)
    expect { client.index(name1) }.to raise_exception(MeiliSearch::ClientError)
    client.delete_index(name2)
    expect { client.index(name2) }.to raise_exception(MeiliSearch::ClientError)
  end
end
