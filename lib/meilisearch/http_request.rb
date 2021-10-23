# frozen_string_literal: true

require 'httparty'
require 'meilisearch/error'

module MeiliSearch
  class HTTPRequest
    include HTTParty

    attr_reader :options

    def initialize(url, api_key = nil, options = {})
      @base_url = url
      @api_key = api_key
      @options = options
      @headers = {
        'Content-Type' => 'application/json',
        'X-Meili-API-Key' => api_key
      }.compact
    end

    def http_get(relative_path = '', query_params = {})
      send_request(
        proc { |path, config| self.class.get(path, config) },
        relative_path,
        query_params
      )
    end

    def http_post(relative_path = '', body = nil, query_params = nil)
      send_request(
        proc { |path, config| self.class.post(path, config) },
        relative_path,
        query_params,
        body
      )
    end

    def http_put(relative_path = '', body = nil, query_params = nil)
      send_request(
        proc { |path, config| self.class.put(path, config) },
        relative_path,
        query_params,
        body
      )
    end

    def http_delete(relative_path = '')
      send_request(
        proc { |path, config| self.class.delete(path, config) },
        relative_path
      )
    end

    private

    SNAKE_CASE = /[^a-zA-Z0-9]+(.)/.freeze

    def send_request(http_method, relative_path, query_params = nil, body = nil)
      config = http_config(query_params, body)
      begin
        response = http_method.call(@base_url + relative_path, config)
      rescue Errno::ECONNREFUSED => e
        raise CommunicationError, e.message
      end
      validate(response)
    end

    def http_config(query_params, body)
      body = transform_attributes(body).to_json

      {
        headers: @headers,
        query: query_params,
        body: body,
        timeout: @options[:timeout] || 1,
        max_retries: @options[:max_retries] || 0
      }.compact
    end

    def transform_attributes(body)
      case body
      when Array
        body.map { |item| transform_attributes(item) }
      when Hash
        parse(body)
      else
        body
      end
    end

    def parse(body)
      body
        .transform_keys(&:to_s)
        .transform_keys do |key|
          key.include?('_') ? key.downcase.gsub(SNAKE_CASE, &:upcase).gsub('_', '') : key
        end
    end

    def validate(response)
      raise ApiError.new(response.code, response.message, response.body) unless response.success?

      response.parsed_response
    end
  end
end
