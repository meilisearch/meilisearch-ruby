# frozen_string_literal: true

RSpec.describe MeiliSearch::Client::Stats do
  before(:all) do
    @client = MeiliSearch::Client.new('http://localhost:8080', 'apiKey')
  end

  it 'has version of server' do
    response = @client.version
    expect(response).to be_a(Hash)
    expect(response).to have_key('commitSha')
    expect(response).to have_key('buildDate')
    expect(response).to have_key('pkgVersion')
  end

  it 'has sys-info' do
    response = @client.sysinfo
    expect(response).to be_a(Hash)
    expect(response).to have_key('memoryUsage')
    expect(response).to have_key('processorUsage')
    expect(response).to have_key('global')
  end

  it 'has stats' do
    response = @client.stats
    expect(response).to have_key('databaseSize')
  end

  context 'stats for a specific index' do
    before(:all) do
      schema = {
        objectId: [:displayed, :indexed, :identifier],
        title: [:displayed, :indexed]
      }
      response = @client.create_index('index_de_test', schema)
      @index_uid = response['uid']
      @documents = [
        { objectId: 123,  title: 'Pride and Prejudice' },
        { objectId: 456,  title: 'Le Petit Prince' }
      ]
      @client.add_documents(@index_uid, @documents)
      sleep(0.1)
    end

    after(:all) do
      @client.delete_index(@index_uid)
    end

    it 'has a number of documents in index' do
      response = @client.number_of_documents_in_index(@index_uid)
      expect(response).to eq(@documents.count)
    end

    it 'has the frequency of fields in index' do
      response = @client.index_fields_frequency(@index_uid)
      expect(response).to be_a(Hash)
    end

    it 'knows when index is indexing' do
      expect(@client.index_is_indexing?(@index_uid)).to be_falsy
    end
  end
end
