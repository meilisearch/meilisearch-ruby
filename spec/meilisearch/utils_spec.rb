# frozen_string_literal: true

RSpec.describe MeiliSearch::Utils do
  describe '.parse_query' do
    it 'transforms arrays into strings' do
      data = described_class.parse_query({ array: [1, 2, 3], other: 'string' }, [:array, :other])

      expect(data).to eq({ 'array' => '1,2,3', 'other' => 'string' })
    end

    it 'cleans list based on another list' do
      data = described_class.parse_query({ array: [1, 2, 3], other: 'string' }, [:array, :other])

      expect(data).to eq({ 'array' => '1,2,3', 'other' => 'string' })
    end
  end
end
