# frozen_string_literal: true

RSpec.describe Meilisearch do
  it 'has a version number' do
    expect(Meilisearch::VERSION).not_to be_nil
  end

  it 'has a qualified version number' do
    expect(described_class.qualified_version).to eq("Meilisearch Ruby (v#{Meilisearch::VERSION})")
  end

  it 'raises an exception when it is impossible to connect' do
    new_client = Meilisearch::Client.new('http://127.0.0.1:8800', 'masterKey')
    expect do
      new_client.indexes
    end.to raise_error(Meilisearch::CommunicationError)
  end

  it 'allows to set a custom timeout and max_retries' do
    new_client = Meilisearch::Client.new(URL, MASTER_KEY, timeout: 20, max_retries: 2)
    expect(new_client.healthy?).to be true
  end

  it 'raises a timeout error when setting the timeout option' do
    new_client = Meilisearch::Client.new(URL, MASTER_KEY, timeout: 0.00001)

    expect do
      new_client.indexes
    end.to raise_error(Meilisearch::TimeoutError)
  end

  it 'has a pre-defined header with current version' do
    new_client = Meilisearch::Client.new(URL, MASTER_KEY)

    expect(new_client.headers).to have_key('User-Agent')
    expect(new_client.headers['User-Agent']).to eq(described_class.qualified_version)
  end

  it 'retries the request when the request is retryable' do
    allow(Meilisearch::HTTPRequest).to receive(:get).and_raise(Net::ReadTimeout)

    begin
      new_client = Meilisearch::Client.new(URL, MASTER_KEY, max_retries: 3, retry_multiplier: 0.1)
      new_client.indexes
    rescue Meilisearch::TimeoutError
      nil
    end

    expect(Meilisearch::HTTPRequest).to have_received(:get).exactly(4).times
  end

  it 'does not retry the request when the request is not retryable' do
    allow(Meilisearch::HTTPRequest).to receive(:get).and_raise(Errno::ECONNREFUSED)

    begin
      new_client = Meilisearch::Client.new(URL, MASTER_KEY, max_retries: 10)
      new_client.indexes
    rescue Meilisearch::CommunicationError
      nil
    end

    expect(Meilisearch::HTTPRequest).to have_received(:get).once
  end
end

RSpec.describe MeiliSearch do
  it 'relays constants & messages, warns about deprecation only once' do
    logger = instance_double(Logger, warn: nil)
    Meilisearch::Utils.logger = logger

    expect(MeiliSearch::Index).to equal(Meilisearch::Index)
    expect(MeiliSearch::Task).to equal(Meilisearch::Task)
    expect(MeiliSearch).to respond_to(:qualified_version)
    expect(MeiliSearch.qualified_version).to eq(Meilisearch.qualified_version)

    expect(logger).to have_received(:warn)
      .with(a_string_including('The top-level module of Meilisearch has been renamed.'))
      .once

    Meilisearch::Utils.logger = nil
  end
end
