# frozen_string_literal: true

RSpec.shared_context 'test defaults' do
  let(:client) { MeiliSearch::Client.new(URL, MASTER_KEY, { timeout: 2, max_retries: 1 }) }

  before do
    clear_all_indexes(client)
    clear_all_keys(client)
  end

  def random_uid
    SecureRandom.hex(4)
  end
end
