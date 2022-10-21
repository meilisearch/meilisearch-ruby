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

    def self.warn_on_non_conforming_attribute_names(body)
      non_snake_case = body.keys.grep_v(/^[a-z0-9_]+$/)

      return if non_snake_case.empty?

      message = <<~MSG
        Attributes will be expected to be snake_case in future versions of Meilisearch Ruby.

        Non-conforming attributes: #{non_snake_case.join(', ')}
      MSG

      warn(message)
    end

    private_class_method :parse
  end
end
