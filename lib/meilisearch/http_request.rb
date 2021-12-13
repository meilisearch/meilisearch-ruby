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
        'Authorization' => "Bearer #{api_key}"
      }.compact
      @headers_no_body = {
        'Authorization' => "Bearer #{api_key}"
      }.compact
    end

    def http_get(relative_path = '', query_params = {})
      send_request(
        proc { |path, config| self.class.get(path, config) },
        relative_path,
        query_params: query_params,
        headers: @headers_no_body
      )
    end

    def http_post(relative_path = '', body = nil, query_params = nil)
      send_request(
        proc { |path, config| self.class.post(path, config) },
        relative_path,
        query_params: query_params,
        body: body,
        headers: @headers
      )
    end

    def http_put(relative_path = '', body = nil, query_params = nil)
      send_request(
        proc { |path, config| self.class.put(path, config) },
        relative_path,
        query_params: query_params,
        body: body,
        headers: @headers
      )
    end

    def http_delete(relative_path = '')
      send_request(
        proc { |path, config| self.class.delete(path, config) },
        relative_path,
        headers: @headers_no_body
      )
    end

    private

    def send_request(http_method, relative_path, query_params: nil, body: nil, headers: nil)
      config = http_config(query_params, body, headers)
      begin
        response = http_method.call(@base_url + relative_path, config)
      rescue Errno::ECONNREFUSED => e
        raise CommunicationError, e.message
      end
      validate(response)
    end

    def http_config(query_params, body, headers)
      {
        headers: headers,
        query: query_params,
        body: body.to_json,
        timeout: @options[:timeout] || 1,
        max_retries: @options[:max_retries] || 0
      }.compact
    end

    def validate(response)
      raise ApiError.new(response.code, response.message, response.body) unless response.success?

      response.parsed_response
    end
  end
end
