# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Search with facetsDistribution' do
  before(:all) do
    @documents = [
      {
        objectId: 123,
        title: 'Pride and Prejudice',
        year: '1813',
        author: 'Jane Austen',
        genre: 'romance'
      },
      {
        objectId: 456,
        title: 'Le Petit Prince',
        year: '1943',
        author: 'Antoine de Saint-Exupéry',
        genre: 'adventure'
      },
      {
        objectId: 1,
        title: 'Alice In Wonderland',
        year: '1865',
        author: 'Lewis Carroll',
        genre: 'adventure'
      },
      {
        objectId: 2,
        title: 'Le Rouge et le Noir',
        year: '1830',
        author: 'Stendhal',
        genre: 'romance'
      },
      {
        objectId: 1344,
        title: 'The Hobbit',
        year: '1937',
        author: 'J. R. R. Tolkien',
        genre: 'adventure'
      },
      {
        objectId: 4,
        title: 'Harry Potter and the Half-Blood Prince',
        year: '2005',
        author: 'J. K. Rowling',
        genre: 'fantasy'
      },
      {
        objectId: 2056,
        title: 'Harry Potter and the Deathly Hallows',
        year: '2007',
        author: 'J. K. Rowling',
        genre: 'fantasy'
      },
      {
        objectId: 42,
        title: 'The Hitchhiker\'s Guide to the Galaxy',
        year: '1978',
        author: 'Douglas Adams'
      },
      {
        objectId: 190,
        title: 'A Game of Thrones',
        year: '1996',
        author: 'George R. R. Martin',
        genre: 'fantasy'
      }
    ]
    client = MeiliSearch::Client.new($URL, $MASTER_KEY)
    clear_all_indexes(client)
    @index = client.create_index('books')
    @index.add_documents(@documents)
    @index.update_attributes_for_faceting(['genre', 'year', 'author'])
    sleep(0.1)
  end

  after(:all) do
    @index.delete
  end

  it 'does a custom search with facetsDistribution' do
    response = @index.search('prinec', facetsDistribution: ['genre', 'author'])
    expect(response.keys).to contain_exactly(
      *$DEFAULT_SEARCH_RESPONSE_KEYS,
      'facetsDistribution',
      'exhaustiveFacetsCount'
    )
    expect(response['exhaustiveFacetsCount']).to be true
    expect(response['nbHits']).to eq(2)
    expect(response['facetsDistribution'].keys).to contain_exactly('genre', 'author')
    expect(response['facetsDistribution']['genre'].keys).to contain_exactly('romance', 'adventure', 'fantasy')
    expect(response['facetsDistribution']['genre']['romance']).to eq(0)
    expect(response['facetsDistribution']['genre']['adventure']).to eq(1)
    expect(response['facetsDistribution']['genre']['fantasy']).to eq(1)
    expect(response['facetsDistribution']['author']['J. K. Rowling']).to eq(1)
    expect(response['facetsDistribution']['author']['Antoine de Saint-Exupéry']).to eq(1)
  end

  it 'does a custom placeholder search with facetsDistribution' do
    response = @index.search('', facetsDistribution: ['genre', 'author'])
    expect(response.keys).to contain_exactly(
      *$DEFAULT_SEARCH_RESPONSE_KEYS,
      'facetsDistribution',
      'exhaustiveFacetsCount'
    )
    expect(response['exhaustiveFacetsCount']).to be true
    expect(response['nbHits']).to eq(@documents.count)
    expect(response['facetsDistribution'].keys).to contain_exactly('genre', 'author')
    expect(response['facetsDistribution']['genre'].keys).to contain_exactly('romance', 'adventure', 'fantasy')
    expect(response['facetsDistribution']['genre']['romance']).to eq(2)
    expect(response['facetsDistribution']['genre']['adventure']).to eq(3)
    expect(response['facetsDistribution']['genre']['fantasy']).to eq(3)
    expect(response['facetsDistribution']['author']['J. K. Rowling']).to eq(2)
  end
end
