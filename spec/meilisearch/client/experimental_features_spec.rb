# frozen_string_literal: true

RSpec.describe 'Meilisearch::Client - Experimental features' do
  describe '#experimental_features' do
    it 'returns the available experimental features' do
      expect(client.experimental_features).to be_kind_of(Hash)
    end
  end

  context '#update_experimental_features' do
    context 'when given one key' do
      it 'updates that one key' do
        feat, status = client.experimental_features.find { |_, v| [true, false].include?(v) }

        pending('This test requires Meilisearch to have a true/false experimental feature') unless feat

        feat_snaked = snake_case_word(feat)

        client.update_experimental_features(feat_snaked => status)
        expect(client.experimental_features).to include(feat => status)

        client.update_experimental_features(feat_snaked => !status)
        expect(client.experimental_features).to include(feat => !status)
      end

      it 'does not change others' do
        prev_features = client.experimental_features

        client.update_experimental_features(metrics: true)
        expect(client.experimental_features).to include(**prev_features.except('metrics'))
      end
    end

    context 'when given all of the keys' do
      it 'sets all keys' do
        edited_features = client.experimental_features.to_h do |feature, val|
          val = !val if [true, false].include?(val)

          [snake_case_word(feature).to_sym, val]
        end

        client.update_experimental_features(edited_features)
        expect(client.experimental_features).to eq(
          Meilisearch::Utils.transform_attributes(edited_features)
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
