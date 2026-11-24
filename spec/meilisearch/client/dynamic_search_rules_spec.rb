# frozen_string_literal: true

RSpec.describe 'Meilisearch::Client - Dynamic search rules' do
  let(:rule_uid) { "promotion-#{random_uid}" }
  let(:rule_options) do
    {
      description: 'Promoted red shirts',
      precedence: 10,
      active: true,
      conditions: {
        query: { words: 'summer sale' },
        filter: { values: { color: 'red', category: 'shirt' } }
      },
      actions: [
        {
          selector: { index_uid: 'products', id: '123' },
          action: { type: 'pin', position: 1 }
        }
      ]
    }
  end

  before do
    client.update_experimental_features(dynamic_search_rules: true)
  end

  after do
    client.delete_dynamic_search_rule(rule_uid).await
  rescue Meilisearch::ApiError
    nil
  end

  def create_rule(uid = rule_uid, options = rule_options)
    client.update_dynamic_search_rule(uid, options).await
  end

  describe '#get_dynamic_search_rules' do
    it 'lists rules with pagination and filtering' do
      second_uid = "promotion-#{random_uid}"
      create_rule
      create_rule(second_uid, rule_options.merge(description: 'Second promotion'))

      response = client.get_dynamic_search_rules(
        offset: 0,
        limit: 1,
        filter: { query: 'summer sale', active: true }
      )

      expect(response).to include('offset' => 0, 'limit' => 1, 'total' => 2)
      expect(response['results'].length).to eq(1)
    ensure
      client.delete_dynamic_search_rule(second_uid).await if second_uid
    end
  end

  describe '#get_dynamic_search_rule' do
    it 'returns a rule including its last update time' do
      create_rule

      rule = client.get_dynamic_search_rule(rule_uid)

      expect(rule).to include(
        'uid' => rule_uid,
        'description' => 'Promoted red shirts',
        'lastUpdatedAt' => be_a(String)
      )
      expect(rule.dig('conditions', 'filter', 'values')).to eq('color' => 'red', 'category' => 'shirt')
    end
  end

  describe '#update_dynamic_search_rule' do
    it 'creates and updates a rule through async tasks' do
      create_task = client.update_dynamic_search_rule(rule_uid, rule_options)
      expect(create_task).to be_a(Meilisearch::Models::Task)
      create_task.await

      update_task = client.update_dynamic_search_rule(rule_uid, description: 'Updated promotion')
      expect(update_task).to be_a(Meilisearch::Models::Task)
      update_task.await

      expect(client.get_dynamic_search_rule(rule_uid)['description']).to eq('Updated promotion')
    end
  end

  describe '#delete_dynamic_search_rule' do
    it 'deletes a rule through an async task' do
      create_rule

      task = client.delete_dynamic_search_rule(rule_uid)
      expect(task).to be_a(Meilisearch::Models::Task)
      task.await

      expect { client.get_dynamic_search_rule(rule_uid) }.to raise_error(Meilisearch::ApiError)
    end
  end
end
