# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Cropped search' do
  before(:all) do
    @documents = [
      {
        objectId: 123,
        title: 'Pride and Prejudice',
        genre: 'romance',
        description: 'Pride and Prejudice is a romantic novel of manners written by Jane Austen in 1813.'
      },
      {
        objectId: 456, title: 'Le Petit Prince',
        genre: 'adventure',
        description: 'Le Petit Prince is a novella by French aristocrat, writer, and aviator Antoine de Saint-Exupéry.'
      },
      {
        objectId: 1,
        title: 'Alice In Wonderland',
        genre: 'adventure',
        desription: 'Alice\'s Adventures in Wonderland is an 1865 novel by English author Lewis Carroll.'
      },
      {
        objectId: 2,
        title: 'Le Rouge et le Noir',
        genre: 'romance',
        description: 'Le Rouge et le Noir is a historical psychological novel in two volumes by Stendhal.'
      },
      {
        objectId: 1344,
        title: 'The Hobbit',
        genre: 'adventure',
        description: 'The Hobbit is a children\'s fantasy novel by English author J. R. R. Tolkien.'
      },
      {
        objectId: 4,
        title: 'Harry Potter and the Half-Blood Prince',
        genre: 'fantasy',
        description: 'Harry Potter and the Half-Blood Prince is a fantasy novel written by J.K. Rowling.'
      },
      {
        objectId: 42,
        title: 'The Hitchhiker\'s Guide to the Galaxy',
        description: 'The Hitchhiker\'s Guide to the Galaxy is a comedy science fiction series by Douglas Adams.'
      }
    ]
    client = MeiliSearch::Client.new($URL, $MASTER_KEY)
    clear_all_indexes(client)
    @index = client.create_index('books')
    response = @index.add_documents(@documents)
    @index.wait_for_pending_update(response['updateId'])
  end

  after(:all) do
    @index.delete
  end

  it 'does a custom search with attributes to crop' do
    response = @index.search('galaxy', { attributesToCrop: ['description'], cropLength: 15 })
    expect(response['hits'].first).to have_key('_formatted')
    expect(response['hits'].first['_formatted']['description']).to eq('s Guide to the Galaxy is a comedy')
  end

  it 'does a custom placehodler search with attributes to crop' do
    response = @index.search('', { attributesToCrop: ['description'], cropLength: 20 })
    expect(response['hits'].first).to have_key('_formatted')
    expect(response['hits'].first['description']).to eq(@documents.first[:description])
    expect(response['hits'].first['_formatted']['description']).not_to eq(@documents.first[:description])
  end
end
