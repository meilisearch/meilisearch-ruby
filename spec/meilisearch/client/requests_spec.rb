# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Client requests' do
  let(:key) { SecureRandom.uuid }

  before(:each) do
    expect(MeiliSearch::Client).to receive(:post)
      .with(kind_of(String), hash_including(body: "{\"primaryKey\":\"#{key}\",\"uid\":\"#{key}\"}"))
      .and_call_original
  end

  it 'parses options when they are in a snake_case' do
    client.create_index(key, primary_key: key, wait: true)

    index = client.fetch_index(key)
    expect(index.uid).to eq(key)
    expect(index.primary_key).to eq(key)
  end

  it 'parses options when they are in a different shape' do
    client.create_index(key, priMARy_kEy: key, wait: true)

    index = client.fetch_index(key)
    expect(index.uid).to eq(key)
    expect(index.primary_key).to eq(key)
  end
end
