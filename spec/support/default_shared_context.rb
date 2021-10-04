# frozen_string_literal: true

RSpec.shared_context 'test defaults' do
  let(:test_client) { MeiliSearch::Client.new(URL, MASTER_KEY) }
  let(:test_uid) { random_uid }

  before do
    clear_all_indexes(test_client)
  end

  def random_uid
    SecureRandom.hex(4)
  end
end
