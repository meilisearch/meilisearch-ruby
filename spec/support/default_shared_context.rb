# frozen_string_literal: true

RSpec.shared_context 'test defaults' do
  let(:client) { MeiliSearch::Client.new(URL, MASTER_KEY) }

  before do
    clear_all_indexes(client)
  end

  def random_uid
    SecureRandom.hex(4)
  end
end
