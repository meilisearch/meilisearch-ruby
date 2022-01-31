# frozen_string_literal: true

require 'httparty'
require 'meilisearch/error'

module MeiliSearch
  class HTTPRequest
    include HTTParty

    attr_reader :options, :headers

    DEFAULT_OPTIONS = {
      timeout: 1,
      max_retries: 0,
      convert_body?: true
    }.freeze

    def initialize(url, api_key = nil, options = {})
      @base_url = url
      @api_key = api_key
      @options = DEFAULT_OPTIONS.merge(options)
      @headers = build_default_options_headers
    end

    def http_get(relative_path = '', query_params = {})
      send_request(
        proc { |path, config| self.class.get(path, config) },
        relative_path,
        config: {
          query_params: query_params,
          headers: remove_headers(@headers.dup, 'Content-Type'),
          options: @options
        }
      )
    end

    def http_post(relative_path = '', body = nil, query_params = nil, options = {})
      send_request(
        proc { |path, config| self.class.post(path, config) },
        relative_path,
        config: {
          query_params: query_params,
          body: body,
          headers: @headers.dup.merge(options[:headers] || {}),
          options: @options.merge(options)
        }
      )
    end

    def http_put(relative_path = '', body = nil, query_params = nil)
      send_request(
        proc { |path, config| self.class.put(path, config) },
        relative_path,
        config: {
          query_params: query_params,
          body: body,
          headers: @headers,
          options: @options
        }
      )
    end

    def http_patch(relative_path = '', body = nil, query_params = nil)
      send_request(
        proc { |path, config| self.class.patch(path, config) },
        relative_path,
        config: {
          query_params: query_params,
          body: body,
          headers: @headers,
          options: @options
        }
      )
    end

    def http_delete(relative_path = '')
      send_request(
        proc { |path, config| self.class.delete(path, config) },
        relative_path,
        config: {
          headers: remove_headers(@headers.dup, 'Content-Type'),
          options: @options
        }
      )
    end

    private

    def build_default_options_headers
      {
        'Content-Type' => 'application/json',
        'Authorization' => ("Bearer #{@api_key}" unless @api_key.nil?),
        'User-Agent' => MeiliSearch.qualified_version
      }.compact
    end

    def remove_headers(data, *keys)
      data.delete_if { |k| keys.include?(k) }
    end

    def send_request(http_method, relative_path, config: {})
      config = http_config(config[:query_params], config[:body], config[:options], config[:headers])

      begin
        response = http_method.call(@base_url + relative_path, config)
      rescue Errno::ECONNREFUSED => e
        raise CommunicationError, e.message
      end

      validate(response)
    end

    def http_config(query_params, body, options, headers)
      body = body.to_json if options[:convert_body?] == true
      {
        headers: headers,
        query: query_params,
        body: body,
        timeout: options[:timeout],
        max_retries: options[:max_retries]
      }.compact
    end

    def validate(response)
      raise ApiError.new(response.code, response.message, response.body) unless response.success?

      response.parsed_response
    end
  end
end
