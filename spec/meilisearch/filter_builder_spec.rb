# frozen_string_literal: true

RSpec.describe Meilisearch::FilterBuilder do
  subject(:builder) { described_class.new }

  describe '.from_hash' do
    it 'builds a filter from a hash' do
      filter = { genres: 'horror' }
      expect(described_class.from_hash(filter)).to eq('genres = horror')
    end
  end

  describe '#build' do
    context 'with direct input types' do
      it 'handles basic values directly' do
        # String values
        expect(builder.build('horror')).to eq('horror')
        expect(builder.build('Jordan Peele')).to eq("'Jordan Peele'")

        # Numeric values
        expect(builder.build(2022)).to eq('2022')
        expect(builder.build(8.5)).to eq('8.5')

        # Boolean values
        expect(builder.build(true)).to eq('true')
        expect(builder.build(false)).to eq('false')

        # Nil value
        expect(builder.build(nil)).to eq('null')

        # Array
        expect(builder.build(['horror', 'comedy'])).to eq('horror AND comedy')
      end
    end

    context 'with basic conditions' do
      it 'handles equality operator' do
        expect(builder.build({ genres: 'horror' })).to eq('genres = horror')
        expect(builder.build({ director: 'Jordan Peele' })).to eq("director = 'Jordan Peele'")
      end

      it 'handles inequality operator' do
        expect(builder.build({ genres: { ne: 'action' } })).to eq('genres != action')
      end

      it 'handles comparison operators' do
        expect(builder.build({ rating: { gt: 85 } })).to eq('rating > 85')
        expect(builder.build({ rating: { lt: 85 } })).to eq('rating < 85')
        expect(builder.build({ rating: { gte: 85 } })).to eq('rating >= 85')
        expect(builder.build({ rating: { lte: 85 } })).to eq('rating <= 85')
      end

      it 'handles range, existence, and collection operators' do
        # Range operator
        expect(builder.build({ rating: { to: [80, 89] } })).to eq('rating 80 TO 89')

        # Existence operators
        expect(builder.build({ field: { exists: true } })).to eq('field EXISTS')
        expect(builder.build({ field: { exists: false } })).to eq('field NOT EXISTS')
        expect(builder.build({ field: { is_empty: true } })).to eq('field IS EMPTY')
        expect(builder.build({ field: { is_empty: false } })).to eq('field IS NOT EMPTY')
        expect(builder.build({ field: { is_null: true } })).to eq('field IS NULL')
        expect(builder.build({ field: { is_null: false } })).to eq('field IS NOT NULL')
        expect(builder.build({ field: nil })).to eq('field IS NULL')

        # Collection operators
        expect(builder.build({ genres: { in: ['horror', 'comedy'] } })).to eq('genres IN [horror, comedy]')
        expect(builder.build({ name: { contains: 'text' } })).to eq('name CONTAINS text')
        expect(builder.build({ name: { starts_with: 'pre' } })).to eq('name STARTS WITH pre')
      end
    end

    context 'with logical operators' do
      it 'handles AND operator (implicit and explicit)' do
        # Implicit AND (multiple attributes)
        filter = { genres: 'horror', director: 'Jordan Peele' }
        expect(builder.build(filter)).to eq("genres = horror AND director = 'Jordan Peele'")

        # Explicit AND
        filter = { and: [{ genres: 'horror' }, { director: 'Jordan Peele' }] }
        expect(builder.build(filter)).to eq("genres = horror AND director = 'Jordan Peele'")
      end

      it 'handles OR operator' do
        filter = { or: [{ genres: 'horror' }, { genres: 'comedy' }] }
        expect(builder.build(filter)).to eq('genres = horror OR genres = comedy')
      end

      it 'handles NOT operator' do
        filter = { not: { genres: 'horror' } }
        expect(builder.build(filter)).to eq('NOT (genres = horror)')

        # Negated expressions with special operators
        expect(builder.build({ not: { genres: { in: ['horror', 'comedy'] } } }))
          .to eq('NOT (genres IN [horror, comedy])')
      end

      it 'handles complex nested conditions with multiple logical operators' do
        # Complex nested logical operators
        filter = {
          and: [
            { or: [{ genres: 'horror' }, { genres: 'comedy' }] },
            { not: { director: 'Jordan Peele' } }
          ]
        }
        filter_string = builder.build(filter)
        expect(filter_string).to eq('(genres = horror OR genres = comedy) AND NOT (director = \'Jordan Peele\')')

        # Nested conditions with a mix of operators
        filter = {
          or: [
            { genres: 'horror' },
            { and: [
              { genres: 'comedy' },
              { release_date: { gt: 795_484_800 } }
            ] }
          ]
        }
        expect(builder.build(filter)).to eq('genres = horror OR (genres = comedy AND release_date > 795484800)')
      end
    end

    context 'with different value types' do
      it 'handles different value types in attributes' do
        # String values (simple and with spaces)
        expect(builder.build({ title: 'Nope' })).to eq('title = Nope')
        expect(builder.build({ title: 'Get Out' })).to eq("title = 'Get Out'")

        # Strings that match operator names get quoted
        expect(builder.build({ title: 'AND' })).to eq("title = 'AND'")
        expect(builder.build({ title: 'NOT' })).to eq("title = 'NOT'")

        # Numeric values
        expect(builder.build({ year: 2022 })).to eq('year = 2022')
        expect(builder.build({ rating: 8.5 })).to eq('rating = 8.5')

        # Boolean values
        expect(builder.build({ available: true })).to eq('available = true')
        expect(builder.build({ available: false })).to eq('available = false')

        # Nil value
        expect(builder.build({ rating: nil })).to eq('rating IS NULL')

        # Array value
        expect(builder.build({ genres: ['horror', 'thriller'] })).to eq('genres IN [horror, thriller]')
      end

      it 'properly formats values in complex expressions' do
        # Multiple attribute types in a single filter
        filter = {
          title: 'Movie',
          year: 2022,
          genres: { in: ['horror', 'comedy'] },
          rating: nil,
          available: true
        }

        result = builder.build(filter)
        expect(result).to include('title = Movie')
        expect(result).to include('year = 2022')
        expect(result).to include('genres IN [horror, comedy]')
        expect(result).to include('rating IS NULL')
        expect(result).to include('available = true')
        expect(result.split(' AND ').size).to eq(5)
      end
    end

    context 'with invalid filters' do
      it 'handles error cases appropriately' do
        # Unsupported filter type
        expect { builder.build(Object.new) }.to raise_error(ArgumentError, /Unsupported filter type/)

        # Unknown operator
        expect { builder.build({ title: { unknown: 'value' } }) }.to raise_error(ArgumentError, /Unknown operator/)

        # Unknown logical operator
        original_operators = Meilisearch::FilterBuilder::LOGICAL_OPERATORS.dup
        stub_const('Meilisearch::FilterBuilder::LOGICAL_OPERATORS', original_operators + [:xor])
        filter = { xor: [{ genres: 'horror' }, { genres: 'comedy' }] }
        expect { builder.build(filter) }.to raise_error(ArgumentError, /Unknown logical operator: xor/)
        stub_const('Meilisearch::FilterBuilder::LOGICAL_OPERATORS', original_operators)
      end
    end
  end

  describe '#process_attribute_conditions' do
    it 'processes non-hash conditions' do
      result = builder.send(:process_attribute_conditions, 'genres', 'horror')
      expect(result).to eq('genres = horror')
    end

    it 'processes multiple conditions on the same attribute' do
      conditions = { gt: 10, lt: 20 }
      result = builder.send(:process_attribute_conditions, 'rating', conditions)
      expect(result).to eq('rating > 10 AND rating < 20')
    end

    it 'processes single condition on an attribute' do
      result = builder.send(:process_attribute_conditions, 'rating', { gt: 10 })
      expect(result).to eq('rating > 10')
    end
  end

  describe '#wrap_complex_condition' do
    it 'wraps conditions with AND' do
      condition = 'genre = horror AND year > 2000'
      expect(builder.send(:wrap_complex_condition, condition)).to eq('(genre = horror AND year > 2000)')
    end

    it 'wraps conditions with OR' do
      condition = 'genre = horror OR genre = comedy'
      expect(builder.send(:wrap_complex_condition, condition)).to eq('(genre = horror OR genre = comedy)')
    end

    it 'checks for special operators in conditions' do
      expect(builder.send(:wrap_complex_condition, 'genres IN [horror, comedy]')).to eq('(genres IN [horror, comedy])')
      expect(builder.send(:wrap_complex_condition, 'field IS EMPTY')).to eq('field IS EMPTY')

      expect(builder.send(:wrap_complex_condition, 'genres IN [horror]')).to eq('(genres IN [horror])')
      expect(builder.send(:wrap_complex_condition, 'name CONTAINS text')).to eq('(name CONTAINS text)')
      expect(builder.send(:wrap_complex_condition, 'name STARTS WITH text')).to eq('(name STARTS WITH text)')
    end

    it 'does not wrap simple conditions' do
      condition = 'genre = horror'
      expect(builder.send(:wrap_complex_condition, condition)).to eq('genre = horror')
    end
  end

  describe '#format_value' do
    context 'with string values' do
      it 'returns simple strings as is' do
        expect(builder.send(:format_value, 'horror')).to eq('horror')
      end

      it 'quotes strings with spaces' do
        expect(builder.send(:format_value, 'Jordan Peele')).to eq("'Jordan Peele'")
      end

      it 'quotes strings matching operator names' do
        expect(builder.send(:format_value, 'IN')).to eq("'IN'")
        expect(builder.send(:format_value, 'and')).to eq("'and'")
      end

      it 'handles quotes in strings' do
        result = builder.send(:format_value, "Jordan's Peele")
        expect(result).to start_with("'")
        expect(result).to end_with("'")
        expect(result.length).to be > 2
      end
    end

    context 'with array values' do
      it 'formats arrays with proper formatting' do
        expect(builder.send(:format_value, ['horror', 'comedy'])).to eq('[horror, comedy]')
        expect(builder.send(:format_value, [1, 2, 3])).to eq('[1, 2, 3]')
        expect(builder.send(:format_value, ['horror', 1, true])).to eq('[horror, 1, true]')
      end
    end

    context 'with other values' do
      it 'formats boolean values' do
        expect(builder.send(:format_value, true)).to eq('true')
        expect(builder.send(:format_value, false)).to eq('false')
      end

      it 'formats nil as null' do
        expect(builder.send(:format_value, nil)).to eq('null')
      end

      it 'converts other values to string' do
        expect(builder.send(:format_value, 123)).to eq('123')
        expect(builder.send(:format_value, 45.67)).to eq('45.67')
      end
    end
  end
end
