# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Cropped search' do
  let(:index) { client.index('books') }
  let(:document) do
    {
      objectId: 42,
      title: 'The Hitchhiker\'s Guide to the Galaxy',
      description: 'The Hitchhiker\'s Guide to the Galaxy is a comedy science fiction series by Douglas Adams.'
    }
  end

  before { index.add_documents!(document) }

  it 'does a custom search with attributes to crop' do
    response = index.search('galaxy', { attributesToCrop: ['description'], cropLength: 6 })
    expect(response['hits'].first).to have_key('_formatted')
    expect(response['hits'].first['_formatted']['description']).to eq('…Guide to the Galaxy is a…')
  end

  it 'does a placehodler search with attributes to crop' do
    response = index.search('', { attributesToCrop: ['description'], cropLength: 5 })
    expect(response['hits'].first).to have_key('_formatted')
    expect(response['hits'].first['description']).to eq(document[:description])
    expect(response['hits'].first['_formatted']['description']).to eq("The Hitchhiker\'s Guide to…")
  end
end
