# frozen_string_literal: true

RSpec.describe 'Meilisearch::Client - Export' do
  it 'creates a new export' do
    task = client.export({ url: 'localhost:7701', indexes: { '*': { overrideSettings: true } } })

    expect(task.type).to eq('export')
  end
end
