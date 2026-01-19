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
    new_client = Meilisearch::Client.new(URL, MASTER_KEY, max_retries: 3, retry_multiplier: 0.1)
    http_client = new_client.instance_variable_get(:@http_client)

    call_count = 0
    allow(http_client).to receive(:get) do
      call_count += 1
      raise HTTP::TimeoutError, 'timeout'
    end

    expect do
      new_client.indexes
    end.to raise_error(Meilisearch::TimeoutError)

    expect(call_count).to eq(4) # 1 initial + 3 retries
  end

  it 'does not retry the request when the request is not retryable' do
    new_client = Meilisearch::Client.new(URL, MASTER_KEY, max_retries: 10)
    http_client = new_client.instance_variable_get(:@http_client)

    call_count = 0
    allow(http_client).to receive(:get) do
      call_count += 1
      raise Errno::ECONNREFUSED
    end

    expect do
      new_client.indexes
    end.to raise_error(Meilisearch::CommunicationError)

    expect(call_count).to eq(1) # no retries for connection refused
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
