# frozen_string_literal: true

RSpec.shared_context 'test defaults' do
  let(:test_client) { MeiliSearch::Client.new(URL, MASTER_KEY) }
  let(:test_uid) { 'test_uid' }
  let(:test_index) { test_client.create_index(test_uid) }

  before do
    clear_all_indexes(test_client)

    # Create the test index after clearing
    test_index
  end
end
