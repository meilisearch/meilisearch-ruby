# frozen_string_literal: true

RSpec.describe MeiliSearch::Client::Indexes do
  before(:all) do
    @client = MeiliSearch::Client.new('http://localhost:8080', 'apiKey')
    @uids = {}
    @index_name1 = SecureRandom.hex(4)
    @index_name2 = SecureRandom.hex(4)
  end

  let(:schema) do
    {
      objectId: [:displayed, :indexed, :identifier],
      title: [:displayed, :indexed]
    }
  end
  let(:new_schema) do
    {
      objectId: [:indexed, :identifier],
      title: [:displayed, :indexed]
    }
  end

  it 'creates an index without schema' do
    response = @client.create_index(@index_name1)
    @uids.merge!(uid1: response['uid'])
    expect(response).to be_a(Hash)
    expect(response['name']).to eq(@index_name1)
    expect(response['schema']).to be_nil
  end

  it 'creates an index with schema' do
    response = @client.create_index(@index_name2, schema)
    @uids.merge!(uid2: response['uid'])
    expect(response).to be_a(Hash)
    expect(response['name']).to eq(@index_name2)
    expect(response['schema']).to be_a(Hash)
  end

  it 'gets list of indexes' do
    response = @client.indexes
    expect(response).to be_a(Array)
    expect(response.count).to be >= 2
    names = response.map { |elem| elem['name'] }
    expect(names).to include(@index_name1)
    expect(names).to include(@index_name2)
  end

  it 'get a specified index' do
    response = @client.index(@uids[:uid2])
    expect(response).to be_a(Hash)
    expect(response['name']).to eq(@index_name2)
  end

  it 'get the schema of a specified index' do
    response = @client.get_index_schema(@uids[:uid2])
    expect(response).to be_a(Hash)
    expect(response).to have_key('objectId')
    expect(response).to have_key('title')
  end

  it 'updates name of index' do
    new_name = 'new name'
    response = @client.update_index_name(@uids[:uid2], new_name)
    expect(response).to be_a(Hash)
    expect(response['name']).to eq(new_name)
  end

  it 'updates schema of index' do
    response = @client.update_index_schema(@uids[:uid2], new_schema)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
  end

  it 'deletes index' do
    @client.delete_index(@uids[:uid1])
    expect { @client.index(@uids[:uid1]) }.to raise_exception(MeiliSearch::ClientError)
    @client.delete_index(@uids[:uid2])
    expect { @client.index(@uids[:uid2]) }.to raise_exception(MeiliSearch::ClientError)
  end
end
