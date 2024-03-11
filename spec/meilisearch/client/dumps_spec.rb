# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client - Dumps' do
  it 'creates a new dump' do
    expect(client.create_dump.await).to be_succeeded
  end
end
