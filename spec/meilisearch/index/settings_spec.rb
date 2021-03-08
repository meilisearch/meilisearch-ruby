# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Settings' do
  before(:all) do
    @client = MeiliSearch::Client.new($URL, $MASTER_KEY)
    clear_all_indexes(@client)
  end

  let(:default_ranking_rules) do
    [
      'typo',
      'words',
      'proximity',
      'attribute',
      'wordsPosition',
      'exactness'
    ]
  end

  let(:settings_keys) do
    [
      'rankingRules',
      'distinctAttribute',
      'searchableAttributes',
      'displayedAttributes',
      'stopWords',
      'synonyms',
      'acceptNewFields',
      'attributesForFaceting'
    ]
  end

  context 'On global settings routes' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }

    it 'gets default values of settings' do
      response = index.settings
      expect(response).to be_a(Hash)
      expect(response.keys).to contain_exactly(*settings_keys)
      expect(response['rankingRules']).to eq(default_ranking_rules)
      expect(response['distinctAttribute']).to be_nil
      expect(response['searchableAttributes']).to eq([])
      expect(response['displayedAttributes']).to eq([])
      expect(response['stopWords']).to eq([])
      expect(response['synonyms']).to eq({})
      expect(response['acceptNewFields']).to be_truthy
    end

    it 'updates multiples settings at the same time' do
      response = index.update_settings(
        rankingRules: ['asc(title)', 'typo'],
        distinctAttribute: 'title'
      )
      expect(response).to have_key('updateId')
      sleep(0.1)
      settings = index.settings
      expect(settings['rankingRules']).to eq(['asc(title)', 'typo'])
      expect(settings['distinctAttribute']).to eq('title')
      expect(settings['stopWords']).to be_empty
    end

    it 'updates one setting without reset the others' do
      response = index.update_settings(stopWords: ['the'])
      expect(response).to have_key('updateId')
      sleep(0.1)
      settings = index.settings
      expect(settings['rankingRules']).to eq(['asc(title)', 'typo'])
      expect(settings['distinctAttribute']).to eq('title')
      expect(settings['stopWords']).to eq(['the'])
      expect(settings['synonyms']).to be_empty
    end

    it 'resets all settings' do
      response = index.reset_settings
      expect(response).to have_key('updateId')
      sleep(0.1)
      settings = index.settings
      expect(settings['rankingRules']).to eq(default_ranking_rules)
      expect(settings['distinctAttribute']).to be_nil
      expect(settings['stopWords']).to be_empty
      expect(settings['synonyms']).to be_empty
    end
  end

  context 'On ranking-rules sub-routes' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }
    let(:ranking_rules) { ['asc(title)', 'words', 'typo'] }
    let(:wrong_ranking_rules) { ['asc(title)', 'typos'] }

    it 'gets default values of ranking rules' do
      response = index.ranking_rules
      expect(response).to eq(default_ranking_rules)
    end

    it 'updates ranking rules' do
      response = index.update_ranking_rules(ranking_rules)
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(index.ranking_rules).to eq(ranking_rules)
    end

    it 'fails when updating with wrong ranking rules name' do
      expect do
        index.update_ranking_rules(wrong_ranking_rules)
      end.to raise_bad_request_meilisearch_api_error
    end

    it 'resets ranking rules' do
      response = index.reset_ranking_rules
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(index.ranking_rules).to eq(default_ranking_rules)
    end
  end

  context 'On distinct-attribute sub-routes' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }
    let(:distinct_attribute) { 'title' }

    it 'gets default values of distinct attribute' do
      response = index.distinct_attribute
      expect(response).to be_nil
    end

    it 'updates distinct attribute' do
      response = index.update_distinct_attribute(distinct_attribute)
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(index.distinct_attribute).to eq(distinct_attribute)
    end

    it 'resets distinct attribute' do
      response = index.reset_distinct_attribute
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(index.distinct_attribute).to be_nil
    end
  end

  context 'On searchable-attributes sub-routes' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }
    let(:searchable_attributes) { ['title', 'description'] }

    it 'gets default values of searchable attributes' do
      response = index.searchable_attributes
      expect(response).to be_a(Array)
      expect(response).to be_empty
    end

    it 'updates searchable attributes' do
      response = index.update_searchable_attributes(searchable_attributes)
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(index.searchable_attributes).to eq(searchable_attributes)
    end

    it 'resets searchable attributes' do
      response = index.reset_searchable_attributes
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(index.get_update_status(response['updateId'])['status']).to eq('processed')
    end
  end

  context 'On displayed-attributes sub-routes' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }
    let(:displayed_attributes) { ['title', 'description'] }

    it 'gets default values of displayed attributes' do
      response = index.displayed_attributes
      expect(response).to be_a(Array)
      expect(response).to be_empty
    end

    it 'updates displayed attributes' do
      response = index.update_displayed_attributes(displayed_attributes)
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(index.displayed_attributes).to contain_exactly(*displayed_attributes)
    end

    it 'resets displayed attributes' do
      response = index.reset_displayed_attributes
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(index.get_update_status(response['updateId'])['status']).to eq('processed')
    end
  end

  context 'On accept-new-fields sub-routes' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }

    it 'gets default values of acceptNewFields' do
      expect(index.accept_new_fields).to be_truthy
    end

    it 'adds searchable or display attributes when truthy' do
      index.update_searchable_attributes(['title', 'description'])
      sleep(0.1)
      index.update_displayed_attributes(['title', 'description'])
      sleep(0.1)
      index.add_documents(id: 1, title: 'Test', comment: 'comment test')
      sleep(0.1)
      sa = index.searchable_attributes
      da = index.displayed_attributes
      expect(sa).to contain_exactly('id', 'title', 'description', 'comment')
      expect(da).to contain_exactly('id', 'title', 'description', 'comment')
      index.update_searchable_attributes([])
      sleep(0.1)
      index.update_displayed_attributes([])
      sleep(0.1)
      index.delete_all_documents
      sleep(0.1)
    end

    it 'updates displayed attributes' do
      response = index.update_accept_new_fields(false)
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(index.accept_new_fields).to be_falsy
    end

    it 'does not add searchable or display attributes when falsy' do
      index.update_searchable_attributes(['title', 'description'])
      sleep(0.1)
      index.update_displayed_attributes(['title', 'description'])
      sleep(0.1)
      index.update_accept_new_fields(false)
      sleep(0.1)
      index.add_documents(id: 1, title: 'Test', comment: 'comment test', note: 'note')
      sleep(0.1)
      sa = index.searchable_attributes
      da = index.displayed_attributes
      expect(sa).to contain_exactly('title', 'description')
      expect(da).to contain_exactly('title', 'description')
    end
  end

  context 'On synonyms sub-routes' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }
    let(:synonyms) do
      {
        wow: ['world of warcraft'],
        wolverine: ['xmen', 'logan'],
        logan: ['wolverine', 'xmen']
      }
    end

    it 'gets an empty hash of synonyms by default' do
      response = index.synonyms
      expect(response).to be_a(Hash)
      expect(response).to be_empty
    end

    it 'returns an updateId when updating' do
      response = index.update_synonyms(synonyms)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
    end

    it 'gets all the synonyms' do
      response = index.synonyms
      expect(response).to be_a(Hash)
      expect(response.count).to eq(3)
      expect(response.keys).to contain_exactly('wow', 'wolverine', 'logan')
      expect(response['wow']).to be_a(Array)
      expect(response['wow']).to eq(['world of warcraft'])
    end

    it 'overwrites all synonyms when updating' do
      response = index.update_synonyms(hp: ['harry potter'], 'harry potter': ['hp'])
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      synonyms = index.synonyms
      expect(synonyms).to be_a(Hash)
      expect(synonyms.count).to eq(2)
      expect(synonyms.keys).to contain_exactly('hp', 'harry potter')
      expect(synonyms['hp']).to be_a(Array)
      expect(synonyms['hp']).to eq(['harry potter'])
    end

    it 'deletes all the synonyms' do
      response = index.reset_synonyms
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      synonyms = index.synonyms
      expect(synonyms).to be_a(Hash)
      expect(synonyms).to be_empty
    end
  end

  context 'On stop-words sub-routes' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }
    let(:stop_words_array) { ['the', 'of'] }
    let(:stop_words_string) { 'a' }

    it 'gets an empty array when there is no stop-words' do
      response = index.stop_words
      expect(response).to be_a(Array)
      expect(response).to be_empty
    end

    it 'updates stop-words when the body is valid (as an array)' do
      response = index.update_stop_words(stop_words_array)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
    end

    it 'gets list of stop-words' do
      response = index.stop_words
      expect(response).to be_a(Array)
      expect(response).to contain_exactly(*stop_words_array)
    end

    it 'updates stop-words when the body is valid (as single string)' do
      response = index.update_stop_words(stop_words_string)
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      sw = index.stop_words
      expect(sw).to be_a(Array)
      expect(sw).to contain_exactly(stop_words_string)
    end

    it 'returns an error when the body is invalid' do
      expect do
        index.update_stop_words(test: 'test')
      end.to raise_bad_request_meilisearch_api_error
    end

    it 'resets stop-words' do
      response = index.reset_stop_words
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(index.stop_words).to be_a(Array)
      expect(index.stop_words).to be_empty
    end
  end

  context 'On attributes-for-faceting sub-routes' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }
    let(:attributes_for_faceting) { ['title', 'description'] }

    it 'gets default values of attributes for faceting' do
      response = index.attributes_for_faceting
      expect(response).to be_a(Array)
      expect(response).to be_empty
    end

    it 'updates attributes for faceting' do
      response = index.update_attributes_for_faceting(attributes_for_faceting)
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(index.attributes_for_faceting).to contain_exactly(*attributes_for_faceting)
    end

    it 'resets attributes for faceting' do
      response = index.reset_attributes_for_faceting
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(index.get_update_status(response['updateId'])['status']).to eq('processed')
      expect(index.attributes_for_faceting).to be_empty
    end
  end

  context 'Index with primary-key' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid, primaryKey: 'id')
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }

    it 'gets the default values of settings' do
      response = index.settings
      expect(response).to be_a(Hash)
      expect(response.keys).to contain_exactly(*settings_keys)
      expect(response['rankingRules']).to eq(default_ranking_rules)
      expect(response['distinctAttribute']).to be_nil
      expect(response['searchableAttributes']).to eq(['id'])
      expect(response['displayedAttributes']).to eq(['id'])
      expect(response['stopWords']).to eq([])
      expect(response['synonyms']).to eq({})
      expect(response['acceptNewFields']).to be_truthy
    end

    it 'updates multiples settings at the same time' do
      response = index.update_settings(
        rankingRules: ['asc(title)', 'typo'],
        distinctAttribute: 'title'
      )
      expect(response).to have_key('updateId')
      sleep(0.1)
      settings = index.settings
      expect(settings['rankingRules']).to eq(['asc(title)', 'typo'])
      expect(settings['distinctAttribute']).to eq('title')
      expect(settings['stopWords']).to be_empty
    end

    it 'updates one setting without reset the others' do
      response = index.update_settings(stopWords: ['the'])
      expect(response).to have_key('updateId')
      sleep(0.1)
      settings = index.settings
      expect(settings['rankingRules']).to eq(['asc(title)', 'typo'])
      expect(settings['distinctAttribute']).to eq('title')
      expect(settings['stopWords']).to eq(['the'])
      expect(settings['synonyms']).to be_empty
    end

    it 'resets all settings' do
      response = index.reset_settings
      expect(response).to have_key('updateId')
      sleep(0.1)
      settings = index.settings
      expect(settings['rankingRules']).to eq(default_ranking_rules)
      expect(settings['distinctAttribute']).to be_nil
      expect(settings['stopWords']).to be_empty
      expect(settings['synonyms']).to be_empty
    end
  end

  context 'Manipulation of searchable/displayed attributes with the primary-key' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }

    it 'does not add document when there is no primary-key' do
      expect do
        index.add_documents(title: 'Test')
      end.to raise_bad_request_meilisearch_api_error
    end

    it 'adds documents when there is a primary-key' do
      response = index.add_documents(objectId: 1, title: 'Test')
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(index.documents.count).to eq(1)
    end

    it 'resets searchable/displayed attributes' do
      response = index.reset_displayed_attributes
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(index.get_update_status(response['updateId'])['status']).to eq('processed')
      response = index.reset_searchable_attributes
      expect(response).to have_key('updateId')
      sleep(0.1)
      expect(index.get_update_status(response['updateId'])['status']).to eq('processed')
    end
  end

  context 'Aliases' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }

    it 'works with method aliases' do
      expect(index.method(:settings) == index.method(:get_settings)).to be_truthy
      expect(index.method(:ranking_rules) == index.method(:get_ranking_rules)).to be_truthy
      expect(index.method(:distinct_attribute) == index.method(:get_distinct_attribute)).to be_truthy
      expect(index.method(:searchable_attributes) == index.method(:get_searchable_attributes)).to be_truthy
      expect(index.method(:displayed_attributes) == index.method(:get_displayed_attributes)).to be_truthy
      expect(index.method(:accept_new_fields) == index.method(:get_accept_new_fields)).to be_truthy
      expect(index.method(:synonyms) == index.method(:get_synonyms)).to be_truthy
      expect(index.method(:stop_words) == index.method(:get_stop_words)).to be_truthy
      expect(index.method(:attributes_for_faceting) == index.method(:get_attributes_for_faceting)).to be_truthy
    end
  end
end
