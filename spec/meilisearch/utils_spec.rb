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
      data = described_class.transform_attributes([
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
  end
end
