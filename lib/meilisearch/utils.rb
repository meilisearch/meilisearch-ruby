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

    def self.parse_query(original_options, allowed_params = [])
      only_allowed_params = original_options.transform_keys(&:to_sym).slice(*allowed_params)

      Utils.transform_attributes(only_allowed_params).then do |body|
        body.transform_values do |v|
          v.respond_to?(:join) ? v.join(',') : v.to_s
        end
      end
    end

    private_class_method :parse
  end
end
