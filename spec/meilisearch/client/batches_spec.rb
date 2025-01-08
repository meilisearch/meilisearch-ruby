# frozen_string_literal: true

RSpec.describe 'Meilisearch::Client - Batches' do
  let(:index) { client.index(random_uid) }

  def new_task
    index.add_documents({ id: 1 })
  end

  describe '#batches' do
    it 'includes the most recent batch' do
      new_task.await

      expect(client.batches).to match(
        'results' => array_including(
          a_hash_including(
            'details' => a_hash_including('receivedDocuments' => 1),
            'stats' => a_hash_including(
              'types' => { 'documentAdditionOrUpdate' => 1 }
            )
          )
        ),
        'total' => anything,
        'limit' => 20,
        'next' => anything,
        'from' => anything
      )
    end

    it 'accepts options such as limit' do
      new_task.await
      new_task.await

      batches = client.batches(limit: 1)
      unlimited_batches = client.batches

      expect(batches['results']).to be_one
      expect(unlimited_batches['results'].count).to be > 1
    end

    it 'allows searching by task uids' do
      new_tasks = Array.new(3) { new_task }

      new_tasks.last.await # give time for meilisearch to batch new tasks
      batches = client.batches(uids: new_tasks.map(&:uid).join(','))

      task_count = batches['results'].sum do |batch|
        batch['stats']['totalNbTasks'].to_i
      end

      expect(task_count).to eq(3)
    end
  end

  context '#batch' do
    it 'shows details of a single batch' do
      new_task.await

      first_batch = client.batches['results'].first
      expect(client.batch(first_batch['uid'])).to eq(first_batch)
    end
  end
end
