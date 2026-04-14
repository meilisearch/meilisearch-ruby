# frozen_string_literal: true

RSpec.describe 'Meilisearch::Client requests' do
  let(:key) { SecureRandom.uuid }

  it 'parses options when they are in a snake_case' do
    client.create_index(key, primary_key: key).await

    index = client.fetch_index(key)
    expect(index.uid).to eq(key)
    expect(index.primary_key).to eq(key)
  end
end
