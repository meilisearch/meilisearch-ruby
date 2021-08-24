# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Settings' do
  before(:all) do
    @client = MeiliSearch::Client.new($URL, $MASTER_KEY)
    clear_all_indexes(@client)
  end

  let(:default_ranking_rules) do
    [
      'words',
      'typo',
      'proximity',
      'attribute',
      'exactness'
    ]
  end
  let(:default_searchable_attributes) { ['*'] }
  let(:default_displayed_attributes) { ['*'] }

  let(:settings_keys) do
    [
      'rankingRules',
      'distinctAttribute',
      'searchableAttributes',
      'displayedAttributes',
      'stopWords',
      'synonyms',
      'filterableAttributes'
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
      expect(response['searchableAttributes']).to eq(default_searchable_attributes)
      expect(response['displayedAttributes']).to eq(default_displayed_attributes)
      expect(response['stopWords']).to eq([])
      expect(response['synonyms']).to eq({})
    end

    it 'updates multiples settings at the same time' do
      response = index.update_settings(
        rankingRules: ['asc(title)', 'typo'],
        distinctAttribute: 'title'
      )
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      settings = index.settings
      expect(settings['rankingRules']).to eq(['asc(title)', 'typo'])
      expect(settings['distinctAttribute']).to eq('title')
      expect(settings['stopWords']).to be_empty
    end

    it 'updates one setting without reset the others' do
      response = index.update_settings(stopWords: ['the'])
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      settings = index.settings
      expect(settings['rankingRules']).to eq(['asc(title)', 'typo'])
      expect(settings['distinctAttribute']).to eq('title')
      expect(settings['stopWords']).to eq(['the'])
      expect(settings['synonyms']).to be_empty
    end

    it 'resets all settings' do
      response = index.reset_settings
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
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
      index.wait_for_pending_update(response['updateId'])
      expect(index.ranking_rules).to eq(ranking_rules)
    end

    it 'updates ranking rules at null' do
      response = index.update_ranking_rules(nil)
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.ranking_rules).to eq(default_ranking_rules)
    end

    it 'fails when updating with wrong ranking rules name' do
      response = index.update_ranking_rules(wrong_ranking_rules)
      index.wait_for_pending_update(response['updateId'])
      response = index.get_update_status(response['updateId'])
      expect(response.keys).to include('message')
      expect(response['errorCode']).to eq('internal')
    end

    it 'resets ranking rules' do
      response = index.reset_ranking_rules
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
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
      index.wait_for_pending_update(response['updateId'])
      expect(index.distinct_attribute).to eq(distinct_attribute)
    end

    it 'updates distinct attribute at null' do
      response = index.update_distinct_attribute(nil)
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.distinct_attribute).to be_nil
    end

    it 'resets distinct attribute' do
      response = index.reset_distinct_attribute
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
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
      expect(response).to eq(default_searchable_attributes)
    end

    it 'updates searchable attributes' do
      response = index.update_searchable_attributes(searchable_attributes)
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.searchable_attributes).to eq(searchable_attributes)
    end

    it 'updates searchable attributes at null' do
      response = index.update_searchable_attributes(nil)
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.searchable_attributes).to eq(default_searchable_attributes)
    end

    it 'resets searchable attributes' do
      response = index.reset_searchable_attributes
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.get_update_status(response['updateId'])['status']).to eq('processed')
      expect(index.searchable_attributes).to eq(default_searchable_attributes)
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
      expect(response).to eq(default_displayed_attributes)
    end

    it 'updates displayed attributes' do
      response = index.update_displayed_attributes(displayed_attributes)
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.displayed_attributes).to contain_exactly(*displayed_attributes)
    end

    it 'updates displayed attributes at null' do
      response = index.update_displayed_attributes(nil)
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.displayed_attributes).to eq(default_displayed_attributes)
    end

    it 'resets displayed attributes' do
      response = index.reset_displayed_attributes
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.get_update_status(response['updateId'])['status']).to eq('processed')
      expect(index.displayed_attributes).to eq(default_displayed_attributes)
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
      index.wait_for_pending_update(response['updateId'])
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
      index.wait_for_pending_update(response['updateId'])
      synonyms = index.synonyms
      expect(synonyms).to be_a(Hash)
      expect(synonyms.count).to eq(2)
      expect(synonyms.keys).to contain_exactly('hp', 'harry potter')
      expect(synonyms['hp']).to be_a(Array)
      expect(synonyms['hp']).to eq(['harry potter'])
    end

    it 'updates synonyms at null' do
      response = index.update_synonyms(nil)
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.synonyms).to be_empty
    end

    it 'deletes all the synonyms' do
      response = index.reset_synonyms
      expect(response).to be_a(Hash)
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
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
      index.wait_for_pending_update(response['updateId'])
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
      index.wait_for_pending_update(response['updateId'])
      sw = index.stop_words
      expect(sw).to be_a(Array)
      expect(sw).to contain_exactly(stop_words_string)
    end

    it 'updates stop-words at null' do
      response = index.update_stop_words(nil)
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.stop_words).to be_empty
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
      index.wait_for_pending_update(response['updateId'])
      expect(index.stop_words).to be_a(Array)
      expect(index.stop_words).to be_empty
    end
  end

  context 'On filterable-attributes sub-routes' do
    before(:all) do
      @uid = SecureRandom.hex(4)
      @client.create_index(@uid)
    end

    after(:all) { clear_all_indexes(@client) }

    let(:index) { @client.index(@uid) }
    let(:filterable_attributes) { ['title', 'description'] }

    it 'gets default values of filterable attributes' do
      response = index.filterable_attributes
      expect(response).to be_a(Array)
      expect(response).to be_empty
    end

    it 'updates filterable attributes' do
      response = index.update_filterable_attributes(filterable_attributes)
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.filterable_attributes).to contain_exactly(*filterable_attributes)
    end

    it 'updates filterable attributes at null' do
      response = index.update_filterable_attributes(nil)
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.filterable_attributes).to be_empty
    end

    it 'resets filterable attributes' do
      response = index.reset_filterable_attributes
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.get_update_status(response['updateId'])['status']).to eq('processed')
      expect(index.filterable_attributes).to be_empty
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
      expect(response['searchableAttributes']).to eq(default_searchable_attributes)
      expect(response['displayedAttributes']).to eq(default_displayed_attributes)
      expect(response['stopWords']).to eq([])
      expect(response['synonyms']).to eq({})
    end

    it 'updates multiples settings at the same time' do
      response = index.update_settings(
        rankingRules: ['asc(title)', 'typo'],
        distinctAttribute: 'title'
      )
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      settings = index.settings
      expect(settings['rankingRules']).to eq(['asc(title)', 'typo'])
      expect(settings['distinctAttribute']).to eq('title')
      expect(settings['stopWords']).to be_empty
    end

    it 'updates one setting without reset the others' do
      response = index.update_settings(stopWords: ['the'])
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      settings = index.settings
      expect(settings['rankingRules']).to eq(['asc(title)', 'typo'])
      expect(settings['distinctAttribute']).to eq('title')
      expect(settings['stopWords']).to eq(['the'])
      expect(settings['synonyms']).to be_empty
    end

    it 'resets all settings' do
      response = index.reset_settings
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
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
      response = index.add_documents(title: 'Test')
      index.wait_for_pending_update(response['updateId'])
      response = index.get_update_status(response['updateId'])
      expect(response.keys).to include('message')
      expect(response['errorCode']).to eq('missing_primary_key')
    end

    it 'adds documents when there is a primary-key' do
      response = index.add_documents(objectId: 1, title: 'Test')
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.documents.count).to eq(1)
    end

    it 'resets searchable/displayed attributes' do
      response = index.reset_displayed_attributes
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.get_update_status(response['updateId'])['status']).to eq('processed')
      response = index.reset_searchable_attributes
      expect(response).to have_key('updateId')
      index.wait_for_pending_update(response['updateId'])
      expect(index.get_update_status(response['updateId'])['status']).to eq('processed')
      expect(index.searchable_attributes).to eq(['*'])
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
      expect(index.method(:synonyms) == index.method(:get_synonyms)).to be_truthy
      expect(index.method(:stop_words) == index.method(:get_stop_words)).to be_truthy
      expect(index.method(:filterable_attributes) == index.method(:get_filterable_attributes)).to be_truthy
    end
  end
end
