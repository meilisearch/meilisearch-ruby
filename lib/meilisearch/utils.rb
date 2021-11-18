# frozen_string_literal: true

module MeiliSearch
  module Utils
    SNAKE_CASE = /[^a-zA-Z0-9]+(.)/.freeze

    def self.transform_attributes(body)
      case body
      when Array
        body.map { |item| transform_attributes(item) }
      when Hash
        parse(body)
      else
        body
      end
    end

    def self.parse(body)
      body
        .transform_keys(&:to_s)
        .transform_keys do |key|
          key.include?('_') ? key.downcase.gsub(SNAKE_CASE, &:upcase).gsub('_', '') : key
        end
    end

    private_class_method :parse
  end
end
