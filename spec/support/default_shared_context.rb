# frozen_string_literal: true

RSpec.shared_context 'test defaults' do
  let(:client) { Meilisearch::Client.new(URL, MASTER_KEY, { timeout: 2, max_retries: 1 }) }
  let(:proxy_client) { Meilisearch::Client.new(PROXY_URL, MASTER_KEY, { timeout: 2, max_retries: 1 }) }

  before do
    clear_all_indexes(client)
    clear_all_keys(client)
  end

  def random_uid
    SecureRandom.hex(4)
  end
end
