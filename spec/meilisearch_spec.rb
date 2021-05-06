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

  it 'allows to set a custom timeout and max_retries' do
    client = MeiliSearch::Client.new('http://127.0.0.1:8800', 'masterKey', timeout: 20, max_retries: 2)
    expect(client.healthy?).to be true
  end

  # Commented test due to random failure.
  # See the related issues:
  # - https://github.com/meilisearch/meilisearch-ruby/issues/168
  # - https://github.com/meilisearch/meilisearch-ruby/issues/178
  #
  # it 'raises a timeout error when setting the timeout option' do
  #   client = MeiliSearch::Client.new($URL, $MASTER_KEY, timeout: 0)
  #   expect do
  #     client.indexes
  #   end.to raise_error(Timeout::Error)
  # end
end
