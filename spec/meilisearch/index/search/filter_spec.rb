# frozen_string_literal: true

RSpec.describe 'MeiliSearch::Index - Filtered search' do
  before(:all) do
    @documents = [
      {
        objectId: 123,
        title: 'Pride and Prejudice',
        year: 1813,
        author: 'Jane Austen',
        genre: 'romance'
      },
      {
        objectId: 456,
        title: 'Le Petit Prince',
        year: 1943,
        author: 'Antoine de Saint-Exupéry',
        genre: 'adventure'
      },
      {
        objectId: 1,
        title: 'Alice In Wonderland',
        year: 1865,
        author: 'Lewis Carroll',
        genre: 'adventure'
      },
      {
        objectId: 2,
        title: 'Le Rouge et le Noir',
        year: 1830,
        author: 'Stendhal',
        genre: 'romance'
      },
      {
        objectId: 1344,
        title: 'The Hobbit',
        year: 1937,
        author: 'J. R. R. Tolkien',
        genre: 'adventure'
      },
      {
        objectId: 4,
        title: 'Harry Potter and the Half-Blood Prince',
        year: 2005,
        author: 'J. K. Rowling',
        genre: 'fantasy'
      },
      {
        objectId: 2056,
        title: 'Harry Potter and the Deathly Hallows',
        year: 2007,
        author: 'J. K. Rowling',
        genre: 'fantasy'
      },
      {
        objectId: 42,
        title: 'The Hitchhiker\'s Guide to the Galaxy',
        year: 1978,
        author: 'Douglas Adams'
      },
      {
        objectId: 190,
        title: 'A Game of Thrones',
        year: 1996,
        author: 'George R. R. Martin',
        genre: 'fantasy'
      }
    ]
    client = MeiliSearch::Client.new($URL, $MASTER_KEY)
    clear_all_indexes(client)
    @index = client.create_index('books')
    response = @index.add_documents(@documents)
    @index.wait_for_pending_update(response['updateId'])
    response = @index.update_filterable_attributes(['genre', 'year', 'author'])
    @index.wait_for_pending_update(response['updateId'])
  end

  after(:all) do
    @index.delete
  end

  it 'does a custom search with one filter' do
    response = @index.search('le', { filter: 'genre = romance' })
    expect(response['hits'].count).to eq(1)
    expect(response['hits'].first['objectId']).to eq(2)
  end

  it 'does a custom search with a numerical value filter' do
    response = @index.search('potter', { filter: 'year = 2007' })
    expect(response['hits'].count).to eq(1)
    expect(response['hits'].first['objectId']).to eq(2056)
  end

  it 'does a custom search with multiple filter' do
    response = @index.search('prince', { filter: 'year > 1930 AND author = "Antoine de Saint-Exupéry"' })
    expect(response['hits'].count).to eq(1)
    expect(response['hits'].first['objectId']).to eq(456)
  end

  it 'does a custom placeholder search with multiple filter' do
    response = @index.search('', { filter: 'author = "J. K. Rowling" OR author = "George R. R. Martin"' })
    expect(response['hits'].count).to eq(3)
  end

  it 'does a custom placeholder search with numerical values filter' do
    response = @index.search('', { filter: 'year < 2000 AND year > 1990' })
    expect(response['hits'].count).to eq(1)
    expect(response['hits'].first['year']).to eq(1996)
  end

  it 'does a custom placeholder search with multiple filter and different type of values' do
    response = @index.search('', { filter: 'author = "J. K. Rowling" AND year > 2006' })
    expect(response['hits'].count).to eq(1)
    expect(response['hits'].first['objectId']).to eq(2056)
  end

  it 'does a custom search with filter and array syntax' do
    response = @index.search('prinec', filter: ['genre = fantasy'])
    expect(response.keys).to contain_exactly(*$DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['nbHits']).to eq(1)
    expect(response['hits'][0]['objectId']).to eq(4)
  end

  it 'does a custom search with multiple filter and array syntax' do
    response = @index.search('potter', filter: ['genre = fantasy', ['year = 2005']])
    expect(response.keys).to contain_exactly(*$DEFAULT_SEARCH_RESPONSE_KEYS)
    expect(response['nbHits']).to eq(1)
    expect(response['hits'][0]['objectId']).to eq(4)
  end
end
