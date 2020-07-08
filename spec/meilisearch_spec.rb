# frozen_string_literal: true

RSpec.describe MeiliSearch do
  it 'has a version number' do
    expect(MeiliSearch::VERSION).not_to be nil
  end

  it 'raises an exception when it is impossible to connect' do
    client = MeiliSearch::Client.new('http://127.0.0.1:8800', 'masterKey')
    expect do
      client.indexes
    end.to raise_error(MeiliSearch::CommunicationError)
  end
end
