# frozen_string_literal: true

RSpec.describe 'Meilisearch::Client - Experimental features' do
  let(:index) { client.index(random_uid) }

  describe '#experimental_features' do
    it 'returns the available experimental features' do
      expect(client.experimental_features).to include(
        'metrics',
        'editDocumentsByFunction',
        'logsRoute',
        'vectorStore',
        'containsFilter'
      )
    end
  end

  context '#update_experimental_features' do
    context 'when given one key' do
      it 'updates that one key' do
        client.update_experimental_features(metrics: true)
        expect(client.experimental_features).to include('metrics' => true)

        client.update_experimental_features(metrics: false)
        expect(client.experimental_features).to include('metrics' => false)
      end

      it 'does not change others' do
        prev_features = client.experimental_features

        client.update_experimental_features(metrics: true)
        expect(client.experimental_features).to include(**prev_features.except('metrics'))
      end
    end

    context 'when given all of the keys' do
      it 'sets all keys' do
        features = client.experimental_features
        features[:metrics] = features.delete('metrics')
        features[:logs_route] = features.delete('logsRoute')
        features[:contains_filter] = !features.delete('containsFilter')
        features[:edit_documents_by_function] = !features.delete('editDocumentsByFunction')
        features[:vector_store] = !features.delete('vectorStore')

        client.update_experimental_features(features)
        expect(client.experimental_features).to eq(
          Meilisearch::Utils.transform_attributes(features)
        )
      end
    end

    context 'when given an invalid feature' do
      it 'raises an error' do
        expect do
          client.update_experimental_features(penguins: true)
        end.to raise_error(Meilisearch::ApiError)
      end
    end
  end
end
