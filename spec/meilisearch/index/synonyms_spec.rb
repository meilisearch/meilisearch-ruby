# frozen_string_literal: true

RSpec.describe MeiliSearch::Index::Synonyms do
  before(:all) do
    @schema = {
      objectId: [:displayed, :indexed, :identifier],
      title: [:displayed, :indexed]
    }
    client = MeiliSearch::Client.new($URL, $API_KEY)
    @index_name = SecureRandom.hex(4)
    @index = client.create_index(@index_name)
  end

  after(:all) do
    @index.delete
  end

  it 'gets an empty hash of synonyms' do
    response = @index.all_synonyms
    expect(response).to be_a(Hash)
    expect(response).to be_empty
  end

  context 'Synonym does not exist' do
    let(:synonym) { 'nope' }

    it 'returns a 404 when the synonym does not exist' do
      skip 'waiting for next version'
      expect { @dex.synonyms_of('nope') }.to raise_meilisearch_http_error_with(404)
    end

    it 'send action to the queue when updating' do
      response = @index.update_synonym(synonym, ['new'])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
    end

    it 'send action to the queue when deleting' do
      response = @index.delete_synonym(synonym)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
    end
  end

  # ONE-WAY SYNONYS - INPUT WITH A SINGLE WORD
  context 'One-way synonyms - when input contains a single word' do
    let(:synonyms) do
      {
        input: 'smartphone',
        synonyms: ['iphone', 'samsung']
      }
    end
    let(:synonyms2) do
      {
        input: 'magician',
        synonyms: ['harry potter', 'merlin']
      }
    end

    it 'creates synonyms (with add_synonyms function)' do
      response = @index.add_synonyms(synonyms)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
    end

    it 'creates synonyms (with add_synonyms_one_way function)' do
      response = @index.add_synonyms_one_way(synonyms2[:input], synonyms2[:synonyms])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
    end

    it 'gets all synonyms' do
      response = @index.all_synonyms
      expect(response).to be_a(Hash)
      expect(response.count).to eq(2)
      expect(response).to have_key(synonyms[:input])
      expect(response[synonyms[:input]]).to be_a(Array)
      expect(response[synonyms[:input]]).to contain_exactly(*synonyms[:synonyms])
      expect(response).to have_key(synonyms2[:input])
      expect(response[synonyms2[:input]]).to be_a(Array)
      expect(response[synonyms2[:input]]).to contain_exactly(*synonyms2[:synonyms])
    end

    it 'gets one sequence' do
      response = @index.synonyms_of(synonyms[:input])
      expect(response).to be_a(Array)
      expect(response).to contain_exactly(*synonyms[:synonyms])
    end

    it 'updates synonyms' do
      new_synonyms = ['oneplus', 'xiaomi']
      response = @index.update_synonym(synonyms[:input], new_synonyms)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(@index.synonyms_of(synonyms[:input])).to contain_exactly(*new_synonyms)
      expect(@index.all_synonyms.count).to eq(2)
    end

    it 'deletes one sequence and its synonyms' do
      response = @index.delete_synonym(synonyms[:input])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      response = @index.delete_synonym(synonyms2[:input])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(@index.all_synonyms).to be_a(Hash)
      expect(@index.all_synonyms).to be_empty
      skip 'waiting for next version' do
        expect { @index.synonyms_of(synonyms[:input]) }.to raise_meilisearch_http_error_with(404)
        expect { @index.synonyms_of(synonyms2[:input]) }.to raise_meilisearch_http_error_with(404)
      end
    end

    it 'batch writes multiples synonyms at the same time' do
      response = @index.batch_write_synonyms([synonyms, synonyms2])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(@index.synonyms_of(synonyms[:input])).to contain_exactly(*synonyms[:synonyms])
      expect(@index.synonyms_of(synonyms2[:input])).to contain_exactly(*synonyms2[:synonyms])
      expect(@index.all_synonyms.count).to eq(2)
    end

    it 'clears all synonyms' do
      response = @index.clear_synonyms
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      response = @index.all_synonyms
      expect(response).to be_a(Hash)
      expect(response).to be_empty
    end
  end

  # ONE-WAY SYNONYMS - INPUT WITH SEVERAL WORDS
  context 'One-way synonyms - when input contains several words' do
    let(:synonyms) do
      {
        input: 'best smartphone',
        synonyms: ['iphone', 'samsung']
      }
    end

    it 'creates synonyms' do
      response = @index.add_synonyms(synonyms)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(@index.all_synonyms.count).to eq(1)
    end

    it 'gets the sequence' do
      skip 'waiting for next version'
      response = @index.synonyms_of(synonyms[:input])
      expect(response).to be_a(Array)
      expect(response).to contain_exactly(*synonyms[:synonyms])
    end

    it 'updates synonyms' do
      skip 'waiting for next version'
      new_synonym = 'google pixel'
      response = @index.update_synonym(synonyms[:input], new_synonym)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(@index.synonyms_of(synonyms[:input])).to contain_exactly(new_synonym)
      expect(@index.all_synonyms.count).to eq(1)
    end

    it 'deletes synonyms' do
      skip 'waiting for next version'
      response = @index.delete_synonym(synonyms[:input])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(@index.all_synonyms).to be_empty
      expect { @index.synonyms_of(synonyms[:input]) }.to raise_meilisearch_http_error_with(404)
    end

    it 'clears all' do
      response = @index.clear_synonyms
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      response = @index.all_synonyms
      expect(response).to be_a(Hash)
      expect(response).to be_empty
    end
  end

  # MULTI-WAY SYNONYMS
  context 'Multi-way synonyms - synonyms with single and several words' do
    let(:synonyms) do
      {
        synonyms: ['hp', 'harry potter']
      }
    end

    let(:synonyms2) do
      {
        synonyms: ['ny', 'new york']
      }
    end

    it 'creates synonyms (with add_synonyms function)' do
      response = @index.add_synonyms(synonyms)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
    end

    it 'creates synonyms (with add_synonyms_multi_way function)' do
      response = @index.add_synonyms_multi_way(synonyms2[:synonyms])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
    end

    it 'gets all synonyms' do
      response = @index.all_synonyms
      expect(response).to be_a(Hash)
      expect(response.count).to eq(4)
      expect(response).to have_key(synonyms[:synonyms][0])
      expect(response).to have_key(synonyms[:synonyms][1])
      expect(response).to have_key(synonyms2[:synonyms][0])
      expect(response).to have_key(synonyms2[:synonyms][1])
    end

    it 'gets each synonym individually' do
      response = @index.synonyms_of(synonyms[:synonyms][0])
      expect(response).to contain_exactly(*synonyms[:synonyms][1])
      response = @index.synonyms_of(synonyms2[:synonyms][0])
      expect(response).to contain_exactly(*synonyms2[:synonyms][1])
      skip 'waiting for next version' do
        response = @index.synonyms_of(synonyms[:synonyms][1])
        expect(response).to contain_exactly(*synonyms[:synonyms][0])
        response = @index.synonyms_of(synonyms2[:synonyms][1])
        expect(response).to contain_exactly(*synonyms2[:synonyms][0])
      end
    end

    it 'updates when synonym contains a single word' do
      new_synonym = ['hewlett packard']
      response = @index.update_synonym('hp', new_synonym)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(@index.synonyms_of('hp')).to contain_exactly(*new_synonym)
      expect(@index.all_synonyms.count).to eq(4)
    end

    it 'updates when synonym contains several words' do
      skip 'waiting for next version'
      new_synonym = ['nyc']
      response = @index.update_synonym('new york', new_synonym)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(@index.synonyms_of('new york')).to contain_exactly(*new_synonym)
      expect(@index.synonyms_of('ny')).to eq(['new york'])
      expect(@index.all_synonyms.count).to eq(4)
    end

    it 'deletes when synonym contains single word' do
      response = @index.delete_synonym(synonyms[:synonyms][0])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(@index.all_synonyms.count).to eq(3)
      skip 'waiting for next version' do
        expect { @index.synonnyms_of(synonyms[:synonyms][0]) }.to raise_meilisearch_http_error_with(404)
      end
    end

    it 'deletes when synonym contains several words' do
      skip 'waiting for next version'
      response = @index.delete_synonym(synonyms2[:synonyms][1])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(@index.all_synonyms.count).to eq(2)
      expect { @index.synonnyms_of(synonyms2[:synonyms][1]) }.to raise_meilisearch_http_error_with(404)
    end

    it 'clears all synonyms' do
      response = @index.clear_all_synonyms
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      response = @index.all_synonyms
      expect(response).to be_a(Hash)
      expect(response).to be_empty
    end
  end

  context 'One and multi-way at the same time' do
    let(:synonyms_one_way) do
      {
        input: 'smartphone',
        synonyms: ['iphone', 'samsung']
      }
    end
    let(:synonyms_multi_way) do
      {
        synonyms: ['hp', 'harry potter']
      }
    end

    it 'batch writes multiples synonyms at the same time' do
      response = @index.batch_write_synonyms([synonyms_one_way, synonyms_multi_way])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
    end

    it 'gets all the synonyms' do
      response = @index.all_synonyms
      expect(response).to have_key(synonyms_one_way[:input])
      expect(response).to have_key(synonyms_multi_way[:synonyms][0])
      expect(response).to have_key(synonyms_multi_way[:synonyms][1])
      expect(response.count).to eq(3)
    end

    it 'gets each synonym individually' do
      response = @index.synonyms_of(synonyms_one_way[:input])
      expect(response).to contain_exactly(*synonyms_one_way[:synonyms])
      response = @index.synonyms_of(synonyms_multi_way[:synonyms][0])
      expect(response).to contain_exactly(synonyms_multi_way[:synonyms][1])
      skip 'waiting for next version' do
        response = @index.synonyms_of(synonyms_multi_way[:synonyms][1])
        expect(response).to contain_exactly(synonyms_multi_way[:synonyms][0])
      end
    end

    it 'clears all the synonyms' do
      response = @index.clear_synonyms
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(@index.all_synonyms).to be_empty
    end
  end

  it 'works with method aliases' do
    expect(@index.method(:synonyms_of) == @index.method(:get_synonyms_of_one_sequence)).to be_truthy
    expect(@index.method(:synonyms_of) == @index.method(:get_synonyms_of)).to be_truthy
    expect(@index.method(:all_synonyms) == @index.method(:get_all_synonyms)).to be_truthy
    expect(@index.method(:all_synonyms) == @index.method(:get_all_sequences)).to be_truthy
    expect(@index.method(:delete_synonym) == @index.method(:delete_one_synonym)).to be_truthy
    expect(@index.method(:clear_synonyms) == @index.method(:clear_all_synonyms)).to be_truthy
  end
end
