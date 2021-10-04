# frozen_string_literal: true

RSpec.shared_context 'search books with genre' do
  let(:index) { test_client.create_index('books') }
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

  before do
    response = index.add_documents(documents)
    index.wait_for_pending_update(response['updateId'])
  end
end
