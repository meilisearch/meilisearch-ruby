# frozen_string_literal: true

require 'httparty'
require 'meilisearch/error'

module MeiliSearch
  class HTTPRequest
    include HTTParty

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
      body = body.to_json unless body.nil?
      {
        headers: @headers,
        query: query_params,
        body: body,
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
