# frozen_string_literal: true

RSpec.describe MeiliSearch::Utils do
  describe '.parse_query' do
    it 'transforms arrays into strings' do
      data = described_class.parse_query({ array: [1, 2, 3], other: 'string' }, [:array, :other])

      expect(data).to eq({ 'array' => '1,2,3', 'other' => 'string' })
    end

    it 'cleans list based on another list' do
      data = described_class.parse_query({ array: [1, 2, 3], ignore: 'string' }, [:array])

      expect(data).to eq({ 'array' => '1,2,3' })
    end

    it 'transforms dates into strings' do
      data = described_class.parse_query({ date: DateTime.new(2012, 12, 21, 19, 5) }, [:date])

      expect(data).to eq({ 'date' => '2012-12-21T19:05:00+00:00' })
    end
  end

  describe '.transform_attributes' do
    it 'transforms snake_case into camelCased keys' do
      data = described_class.transform_attributes({
                                                    index_name: 'books',
                                                    my_UID: '123'
                                                  })

      expect(data).to eq({ 'indexName' => 'books', 'myUid' => '123' })
    end

    it 'transforms snake_case into camel cased keys from array' do
      data = described_class
             .transform_attributes([
                                     { index_uid: 'books', q: 'prince' },
                                     { index_uid: 'movies', q: 'prince' }
                                   ])

      expect(data).to eq(
        [
          { 'indexUid' => 'books', 'q' => 'prince' },
          { 'indexUid' => 'movies', 'q' => 'prince' }
        ]
      )
    end

    it 'warns when using camelCase' do
      attrs = { distinctAttribute: 'title' }

      expect do
        described_class.transform_attributes(attrs)
      end.to output(include('Attributes will be expected to be snake_case', 'distinctAttribute')).to_stderr
    end

    it 'warns when using camelCase in an array' do
      attrs = [
        { 'index_uid' => 'movies', 'q' => 'prince' },
        { 'indexUid' => 'books', 'q' => 'prince' }
      ]

      expect do
        described_class.transform_attributes(attrs)
      end.to output(include('Attributes will be expected to be snake_case', 'indexUid')).to_stderr
    end
  end

  describe '.version_error_handler' do
    it 'spawns same error message' do
      expect do
        described_class.version_error_handler(:my_method) do
          raise MeiliSearch::ApiError.new(405, 'I came from Meili server', {})
        end
      end.to raise_error(MeiliSearch::ApiError, /I came from Meili server/)
    end

    it 'spawns message with version hint' do
      expect do
        described_class.version_error_handler(:my_method) do
          raise MeiliSearch::ApiError.new(405, 'I came from Meili server', {})
        end
      end.to raise_error(MeiliSearch::ApiError, /that `my_method` call requires/)
    end

    it 'adds hints to all error types' do
      expect do
        described_class.version_error_handler(:my_method) do
          raise MeiliSearch::CommunicationError, 'I am an error'
        end
      end.to raise_error(MeiliSearch::CommunicationError, /that `my_method` call requires/)
    end

    describe '.warn_on_non_conforming_attribute_names' do
      it 'warns when using camelCase attributes' do
        attrs = { attributesToHighlight: ['field'] }

        expect do
          described_class.warn_on_non_conforming_attribute_names(attrs)
        end.to output(include('Attributes will be expected to be snake_case', 'attributesToHighlight')).to_stderr
      end

      it 'warns when using a mixed case' do
        attrs = { distinct_ATTribute: 'title' }

        expect do
          described_class.warn_on_non_conforming_attribute_names(attrs)
        end.to output(include('Attributes will be expected to be snake_case', 'distinct_ATTribute')).to_stderr
      end

      it 'does not warn when using snake_case' do
        attrs = { q: 'query', attributes_to_highlight: ['field'] }

        expect do
          described_class.warn_on_non_conforming_attribute_names(attrs)
        end.not_to output.to_stderr
      end
    end
  end
end
