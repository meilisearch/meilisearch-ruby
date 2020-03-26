# frozen_string_literal: true

RSpec.describe MeiliSearch::Index::Synonyms do
  before(:all) do
    client = MeiliSearch::Client.new($URL, $MASTER_KEY)
    clear_all_indexes(client)
    @index = client.create_index('indexUID')
  end

  after(:all) do
    @index.delete
  end

  let(:synonyms) do
    {
      wow: ['world of warcraft'],
      wolverine: ['xmen', 'logan'],
      logan: ['wolverine', 'xmen']
    }
  end

  it 'gets an empty hash of synonyms by default' do
    response = @index.synonyms
    expect(response).to be_a(Hash)
    expect(response).to be_empty
  end

  it 'returns an updateId when updating' do
    response = @index.update_synonyms(synonyms)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    sleep(0.1)
  end

  it 'gets all the synonyms' do
    response = @index.synonyms
    expect(response).to be_a(Hash)
    expect(response.count).to eq(3)
    expect(response.keys).to contain_exactly('wow', 'wolverine', 'logan')
    expect(response['wow']).to be_a(Array)
    expect(response['wow']).to eq(['world of warcraft'])
  end

  it 'overwrites all synonyms when updating' do
    response = @index.update_synonyms(hp: ['harry potter'], 'harry potter': ['hp'])
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    sleep(0.1)
    synonyms = @index.synonyms
    expect(synonyms).to be_a(Hash)
    expect(synonyms.count).to eq(2)
    expect(synonyms.keys).to contain_exactly('hp', 'harry potter')
    expect(synonyms['hp']).to be_a(Array)
    expect(synonyms['hp']).to eq(['harry potter'])
  end

  it 'deletes all the synonyms' do
    response = @index.reset_synonyms
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    sleep(0.1)
    synonyms = @index.synonyms
    expect(synonyms).to be_a(Hash)
    expect(synonyms).to be_empty
  end

  it 'works with method aliases' do
    expect(@index.method(:synonyms) == @index.method(:get_synonyms)).to be_truthy
  end
end
