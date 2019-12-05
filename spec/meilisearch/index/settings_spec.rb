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
    schema = {
      objectId: [:displayed, :indexed, :identifier, :ranked],
      title: [:displayed, :indexed]
    }
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
    expect(response).to have_key('distinctField')
    expect(response).to have_key('rankingRules')
  end

  it 'updates ranking rules' do
    response = @index.update_settings(rankingRules: { objectId: 'asc' })
    expect(response).to have_key('updateId')
    sleep(0.1)
    expect(@index.settings['rankingRules']['objectId']).to eq('asc')
    # search = @index.serach('prince')
    # expect(search['hits'][0]['objectId] < search['hits'][1]['objectId])
  end

  it 'works with method aliases' do
    expect(@index.method(:settings) == @index.method(:get_settings)).to be_truthy
    expect(@index.method(:add_or_update_settings) == @index.method(:add_settings)).to be_truthy
    expect(@index.method(:add_or_update_settings) == @index.method(:update_settings)).to be_truthy
  end

end
