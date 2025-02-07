# frozen_string_literal: true

RSpec.describe 'Meilisearch::Index - Settings' do
  let(:default_ranking_rules) do
    [
      'words',
      'typo',
      'proximity',
      'attribute',
      'sort',
      'exactness'
    ]
  end
  let(:default_searchable_attributes) { ['*'] }
  let(:default_displayed_attributes) { ['*'] }
  let(:default_pagination) { { maxTotalHits: 1000 } }
  let(:default_proximity_precision) { 'byWord' }
  let(:default_search_cutoff_ms) { nil }
  let(:settings_keys) do
    [
      'rankingRules',
      'distinctAttribute',
      'searchableAttributes',
      'displayedAttributes',
      'stopWords',
      'synonyms',
      'filterableAttributes',
      'sortableAttributes',
      'typoTolerance',
      'faceting',
      'pagination',
      'dictionary',
      'nonSeparatorTokens',
      'separatorTokens',
      'proximityPrecision',
      'searchCutoffMs'
    ]
  end
  let(:uid) { random_uid }

  context 'On global settings routes' do
    let(:index) { client.index(uid) }

    before { client.create_index(uid).await }

    it '#settings gets default values of settings' do
      expect(index.settings).to include(
        'rankingRules' => default_ranking_rules,
        'distinctAttribute' => nil,
        'searchableAttributes' => default_searchable_attributes,
        'displayedAttributes' => default_displayed_attributes,
        'stopWords' => [],
        'synonyms' => {},
        'pagination' => default_pagination.transform_keys(&:to_s),
        'filterableAttributes' => [],
        'sortableAttributes' => [],
        'dictionary' => [],
        'separatorTokens' => [],
        'nonSeparatorTokens' => [],
        'proximityPrecision' => default_proximity_precision,
        'searchCutoffMs' => default_search_cutoff_ms
      )
    end

    describe '#update_settings' do
      it 'updates multiples settings at the same time' do
        task = index.update_settings(
          ranking_rules: ['title:asc', 'typo'],
          distinct_attribute: 'title'
        )

        expect(task.type).to eq('settingsUpdate')
        task.await

        expect(index.settings).to include(
          'rankingRules' => ['title:asc', 'typo'],
          'distinctAttribute' => 'title',
          'stopWords' => []
        )
      end

      it 'updates one setting without touching the others' do
        task = index.update_settings(stop_words: ['the'])

        expect(task.type).to eq('settingsUpdate')
        task.await

        expect(index.settings).to include(
          'rankingRules' => default_ranking_rules,
          'distinctAttribute' => nil,
          'stopWords' => ['the'],
          'synonyms' => {}
        )
      end
    end

    it '#reset_settings resets all settings' do
      index.update_settings(
        ranking_rules: ['title:asc', 'typo'],
        distinct_attribute: 'title',
        stop_words: ['the', 'a'],
        synonyms: { wow: ['world of warcraft'] },
        proximity_precision: 'byAttribute',
        search_cutoff_ms: 333
      ).await

      task = index.reset_settings
      expect(task.type).to eq('settingsUpdate')
      task.await

      expect(index.settings).to include(
        'rankingRules' => default_ranking_rules,
        'distinctAttribute' => nil,
        'stopWords' => [],
        'synonyms' => {},
        'proximityPrecision' => default_proximity_precision,
        'searchCutoffMs' => default_search_cutoff_ms
      )
    end
  end

  context 'On ranking rules' do
    let(:index) { client.index(uid) }
    let(:ranking_rules) { ['title:asc', 'words', 'typo'] }
    let(:wrong_ranking_rules) { ['title:asc', 'typos'] }

    before { client.create_index(uid).await }

    it '#ranking_rules gets default values of ranking rules' do
      expect(index.ranking_rules).to eq(default_ranking_rules)
    end

    describe '#update_ranking_rules' do
      it 'updates ranking rules' do
        task = index.update_ranking_rules(ranking_rules)
        expect(task.type).to eq('settingsUpdate')
        task.await

        expect(index.ranking_rules).to eq(ranking_rules)
      end

      it 'resets ranking rules when passed nil' do
        index.update_ranking_rules(ranking_rules).await
        task = index.update_ranking_rules(nil)

        expect(task.type).to eq('settingsUpdate')
        task.await

        expect(index.ranking_rules).to eq(default_ranking_rules)
      end

      it 'fails when updating with wrong ranking rules name' do
        expect do
          index.update_ranking_rules(wrong_ranking_rules)
        end.to raise_meilisearch_api_error_with(400, 'invalid_settings_ranking_rules', 'invalid_request')
      end
    end

    it '#reset_ranking_rules resets ranking rules' do
      index.update_ranking_rules(ranking_rules).await
      task = index.reset_ranking_rules

      expect(task.type).to eq('settingsUpdate')
      task.await

      expect(index.ranking_rules).to eq(default_ranking_rules)
    end
  end

  context 'On distinct attribute' do
    let(:index) { client.index(uid) }
    let(:distinct_attribute) { 'title' }

    before { client.create_index(uid).await }

    it '#distinct_attribute gets default values of distinct attribute' do
      expect(index.distinct_attribute).to be_nil
    end

    describe '#update_distinct_attribute' do
      it 'updates distinct attribute' do
        task = index.update_distinct_attribute(distinct_attribute)
        expect(task.type).to eq('settingsUpdate')
        task.await

        expect(index.distinct_attribute).to eq(distinct_attribute)
      end

      it 'resets district attributes when passed nil' do
        task = index.update_distinct_attribute(distinct_attribute)
        expect(task.type).to eq('settingsUpdate')
        task.await

        task = index.update_distinct_attribute(nil)
        expect(task.type).to eq('settingsUpdate')
        task.await

        expect(index.distinct_attribute).to be_nil
      end
    end

    it '#reset_distinct_attribute resets distinct attribute' do
      task = index.update_distinct_attribute(distinct_attribute)
      expect(task.type).to eq('settingsUpdate')
      task.await

      task = index.reset_distinct_attribute
      expect(task.type).to eq('settingsUpdate')
      task.await

      expect(index.distinct_attribute).to be_nil
    end
  end

  context 'On searchable attributes' do
    let(:index) { client.index(uid) }
    let(:searchable_attributes) { ['title', 'description'] }

    before { client.create_index(uid).await }

    it '#searchable_attributes gets default values of searchable attributes' do
      expect(index.searchable_attributes).to eq(default_searchable_attributes)
    end

    describe '#update_searchable_attributes' do
      it 'updates searchable attributes' do
        task = index.update_searchable_attributes(searchable_attributes)
        expect(task.type).to eq('settingsUpdate')
        task.await

        expect(index.searchable_attributes).to eq(searchable_attributes)
      end

      it 'resets searchable attributes when passed nil' do
        task = index.update_searchable_attributes(searchable_attributes)
        expect(task.type).to eq('settingsUpdate')
        task.await

        task = index.update_searchable_attributes(nil)
        expect(task.type).to eq('settingsUpdate')
        task.await

        expect(index.searchable_attributes).to eq(default_searchable_attributes)
      end
    end

    it '#reset_searchable_attributes resets searchable attributes' do
      task = index.update_searchable_attributes(searchable_attributes)
      expect(task.type).to eq('settingsUpdate')
      task.await

      task = index.reset_searchable_attributes
      expect(task.type).to eq('settingsUpdate')
      expect(task.await).to be_succeeded

      expect(index.searchable_attributes).to eq(default_searchable_attributes)
    end
  end

  context 'On displayed attributes' do
    let(:index) { client.index(uid) }
    let(:displayed_attributes) { ['title', 'description'] }

    before { client.create_index(uid).await }

    it '#displayed_attributes gets default values of displayed attributes' do
      expect(index.displayed_attributes).to eq(default_displayed_attributes)
    end

    describe '#update_displayed_attributes' do
      it 'updates displayed attributes' do
        task = index.update_displayed_attributes(displayed_attributes)

        expect(task.type).to eq('settingsUpdate')
        task.await

        expect(index.displayed_attributes).to contain_exactly(*displayed_attributes)
      end

      it 'resets displayed attributes when passed nil' do
        task = index.update_displayed_attributes(displayed_attributes)
        expect(task.type).to eq('settingsUpdate')
        task.await

        task = index.update_displayed_attributes(nil)
        expect(task.type).to eq('settingsUpdate')
        task.await

        expect(index.displayed_attributes).to eq(default_displayed_attributes)
      end
    end

    it '#reset_displayed_attributes resets displayed attributes' do
      task = index.update_displayed_attributes(displayed_attributes)
      expect(task.type).to eq('settingsUpdate')
      task.await

      task = index.reset_displayed_attributes
      expect(task.type).to eq('settingsUpdate')
      expect(task.await).to be_succeeded

      expect(index.displayed_attributes).to eq(default_displayed_attributes)
    end
  end

  context 'On synonyms' do
    let(:index) { client.index(uid) }
    let(:synonyms) do
      {
        wow: ['world of warcraft'],
        wolverine: ['xmen', 'logan'],
        logan: ['wolverine', 'xmen']
      }
    end

    before { client.create_index(uid).await }

    describe '#synonyms' do
      it 'gets an empty hash of synonyms by default' do
        expect(index.synonyms).to eq({})
      end

      it 'gets all the synonyms' do
        index.update_synonyms(synonyms).await
        expect(index.synonyms).to match(
          'wow' => ['world of warcraft'],
          'wolverine' => ['xmen', 'logan'],
          'logan' => ['wolverine', 'xmen']
        )
      end
    end

    describe '#update_synonyms' do
      it 'overwrites all existing synonyms' do
        index.update_synonyms(synonyms).await
        index.update_synonyms(hp: ['harry potter'], 'harry potter': ['hp']).await

        expect(index.synonyms).to match(
          'hp' => ['harry potter'], 'harry potter' => ['hp']
        )
      end

      it 'resets synonyms when passed nil' do
        index.update_synonyms(synonyms).await
        expect(index.synonyms).not_to be_empty

        index.update_synonyms(nil).await
        expect(index.synonyms).to eq({})
      end
    end

    it '#reset_synonyms deletes all the synonyms' do
      index.update_synonyms(synonyms).await
      expect(index.synonyms).not_to be_empty

      index.reset_synonyms.await
      expect(index.synonyms).to eq({})
    end
  end

  context 'On stop words' do
    let(:index) { client.index(uid) }
    let(:stop_words_array) { ['the', 'of'] }
    let(:stop_words_string) { 'a' }

    before { client.create_index(uid).await }

    describe '#stop_words' do
      it 'gets an empty array when there is no stop-words' do
        expect(index.stop_words).to eq([])
      end

      it 'gets list of stop-words' do
        task = index.update_stop_words(stop_words_array)
        expect(task.type).to eq('settingsUpdate')
        task.await

        expect(index.stop_words).to contain_exactly(*stop_words_array)
      end
    end

    describe '#update_stop_words' do
      it 'updates stop words when passed an array' do
        index.update_stop_words(stop_words_array).await
        expect(index.stop_words).to contain_exactly(*stop_words_array)
      end

      it 'updates stop-words when passed a string' do
        index.update_stop_words(stop_words_string).await
        expect(index.stop_words).to contain_exactly(stop_words_string)
      end

      it 'resets stop words when passed nil' do
        task = index.update_stop_words(stop_words_string)
        expect(task.type).to eq('settingsUpdate')
        task.await

        task = index.update_stop_words(nil)
        expect(task.type).to eq('settingsUpdate')
        task.await

        expect(index.stop_words).to be_empty
      end

      it 'raises an error when the body is invalid' do
        expect do
          index.update_stop_words(test: 'test')
        end.to raise_meilisearch_api_error_with(400, 'invalid_settings_stop_words', 'invalid_request')
      end
    end

    it '#reset_stop_words resets stop-words' do
      task = index.update_stop_words(stop_words_string)
      expect(task.type).to eq('settingsUpdate')
      task.await

      expect(index.stop_words).to contain_exactly(stop_words_string)

      task = index.reset_stop_words
      expect(task.type).to eq('settingsUpdate')
      task.await

      expect(index.stop_words).to eq([])
    end
  end

  context 'On filterable attributes' do
    let(:index) { client.index(uid) }
    let(:filterable_attributes) { ['title', 'description'] }

    before { client.create_index(uid).await }

    it '#filterable_attributes gets default values of filterable attributes' do
      expect(index.filterable_attributes).to eq([])
    end

    describe '#update_filterable_attributes' do
      it 'updates filterable attributes' do
        task = index.update_filterable_attributes(filterable_attributes)
        expect(task.type).to eq('settingsUpdate')
        task.await

        expect(index.filterable_attributes).to contain_exactly(*filterable_attributes)
      end

      it 'resets filterable attributes when passed nil' do
        task = index.update_filterable_attributes(filterable_attributes)
        expect(task.type).to eq('settingsUpdate')
        task.await
        expect(index.filterable_attributes).to contain_exactly(*filterable_attributes)

        task = index.update_filterable_attributes(nil)
        expect(task.type).to eq('settingsUpdate')
        task.await

        expect(index.filterable_attributes).to be_empty
      end
    end

    it '#reset_filterable_attributes resets filterable attributes' do
      task = index.update_filterable_attributes(filterable_attributes)
      expect(task.type).to eq('settingsUpdate')
      task.await
      expect(index.filterable_attributes).to contain_exactly(*filterable_attributes)

      task = index.reset_filterable_attributes
      expect(task.type).to eq('settingsUpdate')
      task.await

      expect(index.filterable_attributes).to be_empty
    end
  end

  context 'On sortable attributes' do
    let(:index) { client.index(uid) }
    let(:sortable_attributes) { ['title', 'description'] }

    before { client.create_index(uid).await }

    it 'gets default values of sortable attributes' do
      expect(index.sortable_attributes).to eq([])
    end

    describe '#update_sortable_attributes' do
      it 'updates sortable attributes' do
        task = index.update_sortable_attributes(sortable_attributes)
        expect(task.type).to eq('settingsUpdate')
        task.await

        expect(index.sortable_attributes).to contain_exactly(*sortable_attributes)
      end

      it 'resets sortable attributes when passed nil' do
        task = index.update_sortable_attributes(sortable_attributes)
        expect(task.type).to eq('settingsUpdate')
        task.await

        expect(index.sortable_attributes).to contain_exactly(*sortable_attributes)

        task = index.update_sortable_attributes(nil)
        expect(task.type).to eq('settingsUpdate')
        task.await

        expect(index.sortable_attributes).to be_empty
      end
    end

    it 'resets sortable attributes' do
      task = index.update_sortable_attributes(sortable_attributes)
      expect(task.type).to eq('settingsUpdate')
      task.await

      expect(index.sortable_attributes).to contain_exactly(*sortable_attributes)

      task = index.reset_sortable_attributes
      expect(task.type).to eq('settingsUpdate')
      task.await

      expect(index.sortable_attributes).to be_empty
    end
  end

  context 'Aliases' do
    let(:index) { client.index(uid) }

    before { client.create_index(uid).await }

    it 'works with method aliases' do
      expect(index.method(:settings)).to eq index.method(:get_settings)
      expect(index.method(:ranking_rules)).to eq index.method(:get_ranking_rules)
      expect(index.method(:distinct_attribute)).to eq index.method(:get_distinct_attribute)
      expect(index.method(:searchable_attributes)).to eq index.method(:get_searchable_attributes)
      expect(index.method(:displayed_attributes)).to eq index.method(:get_displayed_attributes)
      expect(index.method(:synonyms)).to eq index.method(:get_synonyms)
      expect(index.method(:stop_words)).to eq index.method(:get_stop_words)
      expect(index.method(:filterable_attributes)).to eq index.method(:get_filterable_attributes)
    end
  end

  context 'On pagination' do
    let(:index) { client.index(uid) }
    let(:pagination) { { maxTotalHits: 3141 } }
    let(:pagination_with_string_keys) { pagination.transform_keys(&:to_s) }

    before { client.create_index(uid).await }

    it '#pagination gets default values of pagination' do
      expect(index.pagination).to eq(default_pagination.transform_keys(&:to_s))
    end

    describe '#update_pagination' do
      it 'updates pagination' do
        index.update_pagination(pagination).await
        expect(index.pagination).to eq(pagination_with_string_keys)
      end

      it 'resets pagination when passed nil' do
        index.update_pagination(pagination).await
        expect(index.pagination).to eq(pagination_with_string_keys)

        index.update_pagination(nil).await
        expect(index.pagination).to eq(default_pagination.transform_keys(&:to_s))
      end
    end

    it '#reset_pagination resets pagination' do
      index.update_pagination(pagination).await
      expect(index.pagination).to eq(pagination_with_string_keys)

      index.reset_pagination.await
      expect(index.pagination).to eq(default_pagination.transform_keys(&:to_s))
    end
  end

  context 'On typo tolerance' do
    let(:index) { client.index(uid) }

    let(:default_typo_tolerance) do
      {
        'enabled' => true,
        'minWordSizeForTypos' =>
         {
           'oneTypo' => 5,
           'twoTypos' => 9
         },
        'disableOnWords' => [],
        'disableOnAttributes' => []
      }
    end

    let(:new_typo_tolerance) do
      {
        'enabled' => true,
        'min_word_size_for_typos' => {
          'oneTypo' => 6,
          'twoTypos' => 10
        },
        'disable_on_words' => [],
        'disable_on_attributes' => ['title']
      }
    end

    before { client.create_index(uid).await }

    it '#typo_tolerance gets default typo tolerance settings' do
      expect(index.typo_tolerance).to eq(default_typo_tolerance)
    end

    it '#update_type_tolerance updates typo tolerance settings' do
      index.update_typo_tolerance(new_typo_tolerance).await

      expect(index.typo_tolerance).to eq(Meilisearch::Utils.transform_attributes(new_typo_tolerance))
    end

    it '#reset_typo_tolerance resets typo tolerance settings' do
      index.update_typo_tolerance(new_typo_tolerance).await
      expect(index.typo_tolerance).to eq(Meilisearch::Utils.transform_attributes(new_typo_tolerance))

      index.reset_typo_tolerance.await
      expect(index.typo_tolerance).to eq(default_typo_tolerance)
    end
  end

  context 'On faceting' do
    let(:index) { client.index(uid) }
    let(:default_faceting) { { maxValuesPerFacet: 100, sortFacetValuesBy: { '*' => 'alpha' } } }
    let(:default_faceting_with_string_keys) { default_faceting.transform_keys(&:to_s) }

    before { client.create_index(uid).await }

    it '#faceting gets default values of faceting' do
      expect(index.faceting).to eq(default_faceting_with_string_keys)
    end

    describe '#update_faceting' do
      it 'updates faceting' do
        index.update_faceting({ 'max_values_per_facet' => 333 }).await
        new_faceting = default_faceting_with_string_keys.merge('maxValuesPerFacet' => 333)

        expect(index.faceting).to eq(new_faceting)
      end

      it 'resets faceting when passed nil' do
        index.update_faceting({ 'max_values_per_facet' => 333 }).await
        new_faceting = default_faceting_with_string_keys.merge('maxValuesPerFacet' => 333)
        expect(index.faceting).to eq(new_faceting)

        index.update_faceting(nil).await
        expect(index.faceting).to eq(default_faceting_with_string_keys)
      end
    end

    it '#reset_faceting resets faceting' do
      index.update_faceting({ 'max_values_per_facet' => 333 }).await
      new_faceting = default_faceting_with_string_keys.merge('maxValuesPerFacet' => 333)
      expect(index.faceting).to eq(new_faceting)

      index.reset_faceting.await
      expect(index.faceting).to eq(default_faceting_with_string_keys)
    end
  end

  context 'On user-defined dictionary' do
    let(:index) { client.index(uid) }

    before { client.create_index(uid).await }

    it 'has no default value' do
      expect(index.dictionary).to eq([])
    end

    it '#update_dictionary updates dictionary' do
      index.update_dictionary(['J. R. R.', 'W. E. B.']).await
      expect(index.dictionary).to contain_exactly('J. R. R.', 'W. E. B.')
    end

    it '#reset_dictionary resets dictionary' do
      index.update_dictionary(['J. R. R.', 'W. E. B.']).await
      expect(index.dictionary).to contain_exactly('J. R. R.', 'W. E. B.')

      index.reset_dictionary.await
      expect(index.dictionary).to eq([])
    end
  end

  context 'On separator tokens' do
    let(:index) { client.index(uid) }

    before { client.create_index(uid).await }

    it '#separator_tokens has no default value' do
      expect(index.separator_tokens).to eq([])
    end

    it '#update_separator_tokens updates separator tokens' do
      index.update_separator_tokens(['|', '&hellip;']).await
      expect(index.separator_tokens).to contain_exactly('|', '&hellip;')
    end

    it '#reset_separator_tokens resets separator tokens' do
      index.update_separator_tokens(['|', '&hellip;']).await
      expect(index.separator_tokens).to contain_exactly('|', '&hellip;')

      index.reset_separator_tokens.await
      expect(index.separator_tokens).to eq([])
    end

    it '#non_separator_tokens has no default value' do
      expect(index.non_separator_tokens).to eq([])
    end

    it '#update_non_separator_tokens updates non separator tokens' do
      index.update_non_separator_tokens(['@', '#']).await
      expect(index.non_separator_tokens).to contain_exactly('@', '#')
    end

    it '#reset_non_separator_tokens resets non separator tokens' do
      index.update_non_separator_tokens(['@', '#']).await
      expect(index.non_separator_tokens).to contain_exactly('@', '#')

      index.reset_non_separator_tokens.await
      expect(index.non_separator_tokens).to eq([])
    end

    describe '#proximity_precision' do
      it 'has byWord as default value' do
        expect(index.proximity_precision).to eq('byWord')
      end

      it 'updates proximity precision' do
        index.update_proximity_precision('byAttribute').await
        expect(index.proximity_precision).to eq('byAttribute')
      end

      it 'resets proximity precision' do
        index.update_proximity_precision('byAttribute').await
        expect(index.proximity_precision).to eq('byAttribute')

        index.reset_proximity_precision.await
        expect(index.proximity_precision).to eq('byWord')
      end
    end
  end

  context 'On search cutoff' do
    let(:index) { client.index(uid) }
    let(:default_search_cutoff_ms) { nil }

    before { client.create_index(uid).await }

    it '#search_cutoff_ms gets default value' do
      expect(index.search_cutoff_ms).to eq(default_search_cutoff_ms)
    end

    it '#update_search_cutoff_ms updates default value' do
      index.update_search_cutoff_ms(800).await
      expect(index.search_cutoff_ms).to eq(800)
    end

    it '#reset_search_cutoff_ms resets search cutoff ms' do
      index.update_search_cutoff_ms(300).await
      expect(index.search_cutoff_ms).to eq(300)

      index.reset_search_cutoff_ms.await
      expect(index.search_cutoff_ms).to eq(default_search_cutoff_ms)
    end
  end

  context 'On localized attributes' do
    let(:index) { client.index(uid) }
    let(:default_localized_attributes) { nil }

    before { client.create_index(uid).await }

    it '#search_cutoff_ms gets default value' do
      expect(index.localized_attributes).to eq(default_localized_attributes)
    end

    it '#update_localized_attributes updates default value' do
      index.update_localized_attributes(
        [{ attribute_patterns: ['title'], locales: ['eng'] }]
      ).await

      expect(index.localized_attributes).to eq(
        [{ 'attributePatterns' => ['title'], 'locales' => ['eng'] }]
      )
    end

    it '#reset_localized_attributes resets localized attributes' do
      index.update_localized_attributes(
        [{ attribute_patterns: ['title'], locales: ['eng'] }]
      ).await

      expect(index.localized_attributes).to eq(
        [{ 'attributePatterns' => ['title'], 'locales' => ['eng'] }]
      )

      index.reset_localized_attributes.await
      expect(index.localized_attributes).to eq(default_localized_attributes)
    end
  end

  context 'On facet search' do
    let(:index) { client.index(uid) }
    let(:default_facet_search_setting) { true }

    before { client.create_index(uid).await }

    it '#facet_search_setting gets default value' do
      expect(index.facet_search_setting).to eq(default_facet_search_setting)
    end

    it '#update_facet_search_setting updates default value' do
      index.update_facet_search_setting(false).await
      expect(index.facet_search_setting).to eq(false)
    end

    it '#reset_facet_search_setting resets facet search' do
      index.update_facet_search_setting(false).await
      expect(index.facet_search_setting).to eq(false)

      index.reset_facet_search_setting.await
      expect(index.facet_search_setting).to eq(default_facet_search_setting)
    end
  end

  context 'On prefix search' do
    let(:index) { client.index(uid) }
    let(:default_prefix_search) { 'indexingTime' }

    before { client.create_index(uid).await }

    it '#prefix_search gets default value' do
      expect(index.prefix_search).to eq(default_prefix_search)
    end

    it '#update_prefix_search updates default value' do
      index.update_prefix_search('disabled').await
      expect(index.prefix_search).to eq('disabled')
    end

    it '#reset_prefix_search resets prefix search' do
      index.update_prefix_search('disabled').await
      expect(index.prefix_search).to eq('disabled')

      index.reset_prefix_search.await
      expect(index.prefix_search).to eq(default_prefix_search)
    end
  end

  context 'on embedders' do
    let(:index) { client.index(uid) }
    let(:default_embedders) { nil }

    before do
      client.create_index(uid).await
      client.update_experimental_features(vector_store: true)
    end

    it '#embedders gets default value' do
      expect(index.embedders).to eq(default_embedders)
    end

    it '#update_embedders updates default value' do
      index.update_embedders(
        custom: {
          source: 'userProvided',
          dimensions: 3
        }
      ).await

      expect(index.embedders).to have_key('custom')
    end

    it '#reset_embedders resets embedders to nil' do
      index.update_embedders(
        custom: {
          source: 'userProvided',
          dimensions: 3
        }
      ).await

      expect(index.embedders).to have_key('custom')

      index.reset_embedders.await
      expect(index.embedders).to eq(default_embedders)
    end
  end
end
