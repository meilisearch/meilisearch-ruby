# frozen_string_literal: true

RSpec.describe MeiliSearch::Index::StopWords do
  before(:all) do
    @schema = {
      objectId: [:displayed, :indexed, :identifier],
      title: [:displayed, :indexed]
    }
    client = MeiliSearch::Client.new($URL, $API_KEY)
    index_name = SecureRandom.hex(4)
    @index = client.create_index(index_name)
  end

  after(:all) do
    @index.delete
  end

  let(:stop_words_array) { ['the', 'of'] }
  let(:stop_words_string) { 'a' }

  it 'gets an empty array when there is no stop-words' do
    response = @index.stop_words
    expect(response).to be_a(Array)
    expect(response).to be_empty
  end

  it 'adds stop-words when the body is valid (as an array)' do
    response = @index.add_stop_words(stop_words_array)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    sleep(0.1)
  end

  it 'adds stop-words when the body is valid (as single string)' do
    response = @index.add_stop_words(stop_words_string)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    sleep(0.1)
  end

  it 'returns an error when the body is invalid' do
    expect { @index.add_stop_words({ test: 'test'}) }.to raise_meilisearch_http_error_with(400)
  end

  it 'gets list of stop-words' do
    response = @index.stop_words
    expect(response).to be_a(Array)
    expect(response).to contain_exactly(*stop_words_array, stop_words_string)
  end

  it 'deletes stop_words (as array of strings)' do
    response = @index.delete_stop_words(stop_words_array)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    # sleep(0.1)
    # expect(@index.stop_words).to contain_exactly(stop_words_string)
  end

  it 'deletes stop_words (as single string)' do
    response = @index.delete_stop_words(stop_words_array)
    expect(response).to be_a(Hash)
    expect(response).to have_key('updateId')
    # sleep(0.1)
    # expect(@index.stop_words).to be_empty
  end

  it 'works with method aliases' do
    expect(@index.method(:stop_words) == @index.method(:get_stop_words)).to be_truthy
  end
end
