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
end
