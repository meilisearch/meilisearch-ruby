# frozen_string_literal: true

RSpec.shared_context 'search books with genre' do
  let(:index) { client.index('books') }
  let(:documents) do
    [
      { objectId: 123,  title: 'Pride and Prejudice',                    genre: 'romance' },
      { objectId: 456,  title: 'Le Petit Prince',                        genre: 'adventure' },
      { objectId: 1,    title: 'Alice In Wonderland',                    genre: 'adventure' },
      { objectId: 2,    title: 'Le Rouge et le Noir',                    genre: 'romance' },
      { objectId: 1344, title: 'The Hobbit',                             genre: 'adventure' },
      { objectId: 4,    title: 'Harry Potter and the Half-Blood Prince', genre: 'fantasy' },
      { objectId: 42,   title: 'The Hitchhiker\'s Guide to the Galaxy' }
    ]
  end

  before { index.add_documents(documents).await }
end

RSpec.shared_context 'search books with author, genre, year' do
  let(:index) { client.index('books') }
  let(:documents) do
    [
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
  end

  before { index.add_documents(documents).await }
end

RSpec.shared_context 'search books with nested fields' do
  let(:index) { client.index('books') }
  let(:documents) do
    [
      {
        id: 1,
        title: 'Pride and Prejudice',
        info: {
          comment: 'A great book',
          reviewNb: 50
        }
      },
      {
        id: 2,
        title: 'Le Petit Prince',
        info: {
          comment: 'A french book',
          reviewNb: 600
        }
      },
      {
        id: 3,
        title: 'Le Rouge et le Noir',
        info: {
          comment: 'Another french book',
          reviewNb: 700
        }
      },
      {
        id: 4,
        title: 'Alice In Wonderland',
        info: {
          comment: 'A weird book',
          reviewNb: 800
        }
      },
      {
        id: 5,
        title: 'The Hobbit',
        info: {
          comment: 'An awesome book',
          reviewNb: 900
        }
      },
      {
        id: 6,
        title: 'Harry Potter and the Half-Blood Prince',
        info: {
          comment: 'The best book',
          reviewNb: 1000
        }
      },
      {
        id: 7,
        title: 'The Hitchhiker\'s Guide to the Galaxy'
      },
      {
        id: 8,
        title: 'Harry Potter and the Deathly Hallows',
        info: {
          comment: 'The best book again',
          reviewNb: 1000
        }
      }
    ]
  end

  before { index.add_documents(documents).await }
end
