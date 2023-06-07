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

  before { index.add_documents(document, wait: true) }

  it 'searches with default cropping params' do
    response = index.search('galaxy', attributesToCrop: ['*'], cropLength: 6)

    expect(response.dig('hits', 0, '_formatted', 'description')).to eq('…Guide to the Galaxy is a…')
  end

  it 'searches with custom crop markers' do
    response = index.search('galaxy', attributesToCrop: ['*'], cropLength: 6, cropMarker: '(ꈍᴗꈍ)')

    expect(response.dig('hits', 0, '_formatted', 'description')).to eq('(ꈍᴗꈍ)Guide to the Galaxy is a(ꈍᴗꈍ)')
  end

  it 'searches with mixed highlight and crop config' do
    response = index.search(
      'galaxy',
      attributesToHighlight: ['*'],
      attributesToCrop: ['*'],
      highlightPreTag: '<span class="bold">'
    )

    expect(response.dig('hits', 0, '_formatted', 'description')).to \
      eq("…Hitchhiker's Guide to the <span class=\"bold\">Galaxy</em> is a comedy science…")
  end

  it 'searches with highlight tags' do
    response = index.search(
      'galaxy',
      attributesToHighlight: ['*'],
      highlightPreTag: '<span>',
      highlightPostTag: '</span>'
    )

    expect(response.dig('hits', 0, '_formatted', 'description')).to include('<span>Galaxy</span>')
  end

  it 'does a custom search with attributes to crop' do
    response = index.search('galaxy', { attributesToCrop: ['description'], cropLength: 6 })
    expect(response['hits'].first).to have_key('_formatted')
    expect(response['hits'].first['_formatted']['description']).to eq('…Guide to the Galaxy is a…')
  end

  it 'does a placehodler search with attributes to crop' do
    response = index.search('', { attributesToCrop: ['description'], cropLength: 5 })
    expect(response['hits'].first).to have_key('_formatted')
    expect(response['hits'].first['description']).to eq(document[:description])
    expect(response['hits'].first['_formatted']['description']).to eq("The Hitchhiker's Guide to…")
  end
end
