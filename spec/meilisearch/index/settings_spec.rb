# frozen_string_literal: true

RSpec.describe MeiliSearch::Index::Settings do
  before(:all) do
    documents = [
      { objectId: 123,  title: 'Pride and Prejudice' },
      { objectId: 456,  title: 'Le Petit Prince' },
      { objectId: 1,    title: 'Alice In Wonderland' },
      { objectId: 1344, title: 'The Hobbit' },
      { objectId: 4,    title: 'Harry Potter and the Half-Blood Prince' },
      { objectId: 42,   title: 'The Hitchhiker\'s Guide to the Galaxy' }
    ]
    client = MeiliSearch::Client.new($URL, $API_KEY)
    @index = client.create_index('Index name')
    @index.add_documents(documents)
    sleep(0.1)
  end

  after(:all) do
    @index.delete
  end

  it 'gets index settings' do
    response = @index.settings
    expect(response).to be_a(Hash)
    expect(response).not_to be_empty
    expect(response).to have_key('rankingOrder')
    expect(response['rankingOrder']).to eq(nil)
    expect(response).to have_key('distinctField')
    expect(response['distinctField']).to eq(nil)
    expect(response).to have_key('rankingRules')
    expect(response['rankingRules']).to eq(nil)
  end

  it 'add ranking rules' do
    response = @index.add_settings(rankingRules: { objectId: 'asc' })
    expect(response).to have_key('updateId')
    sleep(0.1)
    expect(@index.settings['rankingRules']['objectId']).to eq('asc')
    skip 'waiting for next version' do
      search = @index.search('prince')
      expect(search['hits'][0]['objectId'] < search['hits'][1]['objectId'])
    end
  end

  it 'replaces ranking rules' do
    response = @index.replace_settings(rankingRules: { title: 'asc' })
    expect(response).to have_key('updateId')
    sleep(0.1)
    settings = @index.settings
    expect(settings['rankingRules']['title']).to eq('asc')
    expect(settings['rankingRules']).not_to have_key('objectId')
  end

  it 'resets all settings' do
    response = @index.reset_all_settings
    expect(response).to have_key('updateId')
    sleep(0.1)
    skip 'waiting for next version' do
      settings = @index.settings
      expect(settings).to have_key('rankingOrder')
      expect(settings['rankingOrder']).to eq(nil)
      expect(settings).to have_key('distinctField')
      expect(settings['distinctField']).to eq(nil)
      expect(settings).to have_key('rankingRules')
      expect(settings['rankingRules']).to eq(nil)
    end
  end

  it 'works with method aliases' do
    expect(@index.method(:settings) == @index.method(:get_settings)).to be_truthy
    expect(@index.method(:add_or_replace_settings) == @index.method(:add_settings)).to be_truthy
    expect(@index.method(:add_or_replace_settings) == @index.method(:replace_settings)).to be_truthy
  end
end
