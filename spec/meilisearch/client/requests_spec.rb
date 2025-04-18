# frozen_string_literal: true

RSpec.describe 'Meilisearch::Client requests' do
  let(:key) { SecureRandom.uuid }

  before do
    expect(Meilisearch::Client).to receive(:post)
      .with(kind_of(String), hash_including(body: "{\"primaryKey\":\"#{key}\",\"uid\":\"#{key}\"}"))
      .and_call_original
  end

  it 'parses options when they are in a snake_case' do
    client.create_index(key, primary_key: key).await

    index = client.fetch_index(key)
    expect(index.uid).to eq(key)
    expect(index.primary_key).to eq(key)
  end
end
