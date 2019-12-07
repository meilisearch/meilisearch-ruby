# frozen_string_literal: true

RSpec.describe MeiliSearch::Index::Updates do
  before(:all) do
    @documents = [
      { objectId: 123,  title: 'Pride and Prejudice' },
      { objectId: 456,  title: 'Le Petit Prince' },
      { objectId: 1,    title: 'Alice In Wonderland' },
      { objectId: 1344, title: 'The Hobbit' },
      { objectId: 4,    title: 'Harry Potter and the Half-Blood Prince' },
      { objectId: 42,   title: 'The Hitchhiker\'s Guide to the Galaxy' }
    ]
    schema = {
      objectId: [:displayed, :indexed, :identifier, :ranked],
      title: [:displayed, :indexed]
    }
    client = MeiliSearch::Client.new($URL, $API_KEY)
    @index = client.create_index('Index name')
  end

  after(:all) do
    @index.delete
  end

  it 'gets an empty array when nothing happened before' do
    response = @index.get_all_update_status
    expect(response).to be_a(Array)
    expect(response).to be_empty
  end

  it 'gets update status after adding documents' do
    response = @index.add_documents(@documents)
    update_id = response['updateId']
    sleep(0.2)
    response = @index.get_update_status(update_id)
    expect(response).to be_a(Hash)
    expect(response['updateId']).to eq(update_id)
    expect(response['status']).to eq('processed')
    expect(response['type']).to be_a(Hash)
  end

  it 'gets all the update status' do
    response = @index.get_all_update_status
    expect(response).to be_a(Array)
    expect(response.count).to eq(2) # DocumentionAddition + Schema
  end

end
