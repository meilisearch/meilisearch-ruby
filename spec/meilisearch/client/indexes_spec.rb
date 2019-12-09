# frozen_string_literal: true

RSpec.describe MeiliSearch::Client::Indexes do
  before(:all) do
    @client = MeiliSearch::Client.new($URL, $API_KEY)
    clear_all_indexes(@client)
    @uid1 = 'uid1'
    @uid2 = 'uid2'
    @index_name1 = SecureRandom.hex(4)
    @index_name2 = SecureRandom.hex(4)
  end

  let(:schema) do
    {
      objectId: [:displayed, :indexed, :identifier],
      title: [:displayed, :indexed]
    }
  end

  it 'creates an index with name and uid' do
    index = @client.create_index(name: @index_name1, uid: @uid1)
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.name).to eq(@index_name1)
    expect(index.uid).not_to be_empty
    expect(index.schema).to be_nil
  end

  it 'creates an index with name, uid and schema' do
    index = @client.create_index(name: @index_name2, uid: @uid2, schema: schema)
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.name).to eq(@index_name2)
    expect(index.uid).not_to be_empty
    fetched_schema = index.schema
    expect(fetched_schema).to be_a(Hash)
    expect(fetched_schema['objectId']).to contain_exactly(*schema[:objectId].map(&:to_s))
    expect(fetched_schema['title']).to contain_exactly(*schema[:title].map(&:to_s))
  end

  it 'creates an index with only a name' do
    name = 'Name'
    index = @client.create_index(name)
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.name).to eq(name)
    expect(index.uid).not_to be_empty
    expect(index.schema).to be_nil
    expect(index.delete).to be_nil
  end

  it 'fails to create an index with an uid already taken' do
    name = 'Failure'
    uid = @uid1
    expect do
      @client.create_index(name: name, uid: uid)
    end.to raise_meilisearch_http_error_with(400)
  end

  it 'gets list of indexes' do
    response = @client.indexes
    expect(response).to be_a(Array)
    expect(response.count).to be >= 2
    names = response.map { |elem| elem['name'] }
    expect(names).to contain_exactly(@index_name1, @index_name2)
  end

  it 'shows a specific index' do
    response = @client.show_index(@uid1)
    expect(response).to be_a(Hash)
    expect(response['name']).to eq(@index_name1)
    expect(response['uid']).to eq(@uid1)
  end

  it 'returns an index object based on uid' do
    index = @client.index(@uid1)
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.name).to eq(@index_name1)
    expect(index.uid).to eq(@uid1)
  end

  it 'returns an index object based on uid (as an hash)' do
    index = @client.index(uid: @uid1)
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.name).to eq(@index_name1)
    expect(index.uid).to eq(@uid1)
  end

  it 'returns an index object based on name' do
    index = @client.index(name: @index_name2)
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.name).to eq(@index_name2)
    expect(index.uid).to eq(@uid2)
  end

  it 'fails to return an index object when the name that does not exists' do
    expect { @client.index(name: 'nope') }.to raise_exception(MeiliSearch::IndexIdentifierError)
  end

  it 'returns an index object based on uid and name (does not take the name into account)' do
    index = @client.index(uid: @uid2, name: 'nope')
    expect(index).to be_a(MeiliSearch::Index)
    expect(index.name).to eq(@index_name2)
    expect(index.uid).to eq(@uid2)
  end

  it 'deletes index' do
    expect(@client.delete_index(@uid1)).to be_nil
    expect { @client.show_index(@uid1) }.to raise_meilisearch_http_error_with(404)
    expect(@client.delete_index(@uid2)).to be_nil
    expect { @client.show_index(@uid2) }.to raise_meilisearch_http_error_with(404)
  end

  it 'works with method aliases' do
    expect(@client.method(:index) == @client.method(:get_index)).to be_truthy
  end
end
