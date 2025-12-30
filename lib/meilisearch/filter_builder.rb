# frozen_string_literal: true

module Meilisearch
  class FilterBuilder
    OPERATORS = {
      eq: '=',
      ne: '!=',
      gt: '>',
      gte: '>=',
      lt: '<',
      lte: '<=',
      to: 'TO',
      exists: 'EXISTS',
      in: 'IN',
      contains: 'CONTAINS',
      starts_with: 'STARTS WITH',
      is_empty: 'IS EMPTY',
      is_null: 'IS NULL'
    }.freeze

    LOGICAL_OPERATORS = [:and, :or, :not].freeze

    def self.from_hash(hash) = new.build(hash)

    def build(filter)
      case filter
      when Hash then process_hash(filter)
      when Array then filter.map { build(_1) }.join(' AND ')
      when String, Numeric, TrueClass, FalseClass then format_value(filter)
      when nil then 'null'
      else raise ArgumentError, "Unsupported filter type: #{filter.class}"
      end
    end

    private

    def process_hash(hash)
      if logical_operator?(hash)
        build_logical_expression(hash)
      elsif hash.size == 1
        build_single_attribute_expression(hash)
      else
        build_multi_attribute_expression(hash)
      end
    end

    def logical_operator?(hash) = hash.keys.any? { |k| LOGICAL_OPERATORS.include?(k.to_sym) }

    def build_logical_expression(hash)
      logical_op = hash.keys.find { |k| LOGICAL_OPERATORS.include?(k.to_sym) }
      op_sym = logical_op.to_sym

      case op_sym
      when :and then build_and_expression(hash, logical_op)
      when :or then build_or_expression(hash, logical_op)
      when :not then build_not_expression(hash, logical_op)
      else raise ArgumentError, "Unknown logical operator: #{logical_op}"
      end
    end

    def build_and_expression(hash, logical_op)
      conditions = get_conditions_array(hash, logical_op)
      conditions.map { |c| wrap_complex_condition(build(c)) }.join(' AND ')
    end

    def build_or_expression(hash, logical_op)
      conditions = get_conditions_array(hash, logical_op)
      conditions.map { |c| wrap_complex_condition(build(c)) }.join(' OR ')
    end

    def build_not_expression(hash, logical_op) = "NOT (#{build(hash[logical_op] || hash[logical_op.to_s])})"

    def get_conditions_array(hash, logical_op) = Array(hash[logical_op] || hash[logical_op.to_s])

    def build_single_attribute_expression(hash)
      attribute, conditions = hash.first

      if conditions.is_a?(Hash)
        process_attribute_conditions(attribute, conditions)
      elsif conditions.nil?
        "#{attribute} IS NULL"
      elsif conditions.is_a?(Array)
        "#{attribute} IN #{format_value(conditions)}"
      else
        "#{attribute} = #{format_value(conditions)}"
      end
    end

    def build_multi_attribute_expression(hash)
      hash.map do |attribute, value|
        build_single_attribute_expression({ attribute => value })
      end.join(' AND ')
    end

    def process_attribute_conditions(attribute, conditions)
      if conditions.is_a?(Hash)
        expressions = build_operator_expressions(attribute, conditions)

        if expressions.size > 1
          expressions.map { |e| wrap_complex_condition(e) }.join(' AND ')
        else
          expressions.first
        end
      else
        "#{attribute} = #{format_value(conditions)}"
      end
    end

    def build_operator_expressions(attribute, conditions)
      conditions.map do |operator, value|
        operator = operator.to_sym

        raise ArgumentError, "Unknown operator: #{operator}" unless OPERATORS.key?(operator)

        build_operator_expression(attribute, operator, value)
      end
    end

    def build_operator_expression(attribute, operator, value) # rubocop:disable Metrics/CyclomaticComplexity
      case operator
      when :exists then value ? "#{attribute} EXISTS" : "#{attribute} NOT EXISTS"
      when :in then "#{attribute} IN [#{format_array_values(value)}]"
      when :to then "#{attribute} #{format_value(value.first)} TO #{format_value(value.last)}"
      when :is_empty then value ? "#{attribute} IS EMPTY" : "#{attribute} IS NOT EMPTY"
      when :is_null then value ? "#{attribute} IS NULL" : "#{attribute} IS NOT NULL"
      when :contains then "#{attribute} CONTAINS #{format_value(value)}"
      when :starts_with then "#{attribute} STARTS WITH #{format_value(value)}"
      else "#{attribute} #{OPERATORS[operator]} #{format_value(value)}"
      end
    end

    def format_array_values(values) = Array(values).map { |v| format_value(v) }.join(', ')

    def format_value(value)
      case value
      when String then format_string_value(value)
      when Array then format_array_value(value)
      when true then 'true'
      when false then 'false'
      when nil then 'null'
      else value.to_s
      end
    end

    def format_string_value(string) = needs_quoting?(string) ? "'#{string.gsub("'", "\\'")}'" : string

    def needs_quoting?(string)
      string.include?(' ') ||
        OPERATORS.value?(string.upcase) ||
        LOGICAL_OPERATORS.map { |x| x.to_s.upcase }.include?(string.upcase)
    end

    def format_array_value(array) = "[#{array.map { |v| format_value(v) }.join(', ')}]"

    def wrap_complex_condition(condition) = complex_condition?(condition) ? "(#{condition})" : condition

    def complex_condition?(condition)
      condition.include?(' AND ') ||
        condition.include?(' OR ') ||
        condition.match?(/\s(IN|CONTAINS|STARTS WITH|IS EMPTY|IS NULL|NOT EXISTS|IS NOT EMPTY|IS NOT NULL)\s/)
    end
  end
end
