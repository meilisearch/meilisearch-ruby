# frozen_string_literal: true

require 'httparty'
require 'meilisearch/error'

module Meilisearch
  class HTTPRequest
    include HTTParty

    attr_reader :options, :headers

    DEFAULT_OPTIONS = {
      timeout: 10,
      max_retries: 2,
      retry_multiplier: 1.2,
      convert_body?: true
    }.freeze

    def initialize(url, api_key = nil, options = {})
      @base_url = url
      @api_key = api_key
      @options = DEFAULT_OPTIONS.merge(options)
      @headers = build_default_options_headers
    end

    def http_get(relative_path = '', query_params = {}, options = {})
      send_request(
        proc { |path, config| self.class.get(path, config) },
        relative_path,
        config: {
          query_params: query_params,
          headers: remove_headers(@headers.dup.merge(options[:headers] || {}), 'Content-Type'),
          options: @options.merge(options),
          method_type: :get
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
          options: @options.merge(options),
          method_type: :post
        }
      )
    end

    def http_put(relative_path = '', body = nil, query_params = nil, options = {})
      send_request(
        proc { |path, config| self.class.put(path, config) },
        relative_path,
        config: {
          query_params: query_params,
          body: body,
          headers: @headers.dup.merge(options[:headers] || {}),
          options: @options.merge(options),
          method_type: :put
        }
      )
    end

    def http_patch(relative_path = '', body = nil, query_params = nil, options = {})
      send_request(
        proc { |path, config| self.class.patch(path, config) },
        relative_path,
        config: {
          query_params: query_params,
          body: body,
          headers: @headers.dup.merge(options[:headers] || {}),
          options: @options.merge(options),
          method_type: :patch
        }
      )
    end

    def http_delete(relative_path = '', query_params = nil, options = {})
      send_request(
        proc { |path, config| self.class.delete(path, config) },
        relative_path,
        config: {
          query_params: query_params,
          headers: remove_headers(@headers.dup.merge(options[:headers] || {}), 'Content-Type'),
          options: @options.merge(options),
          method_type: :delete
        }
      )
    end

    private

    def build_default_options_headers
      {
        'Content-Type' => 'application/json',
        'Authorization' => ("Bearer #{@api_key}" unless @api_key.nil?),
        'User-Agent' => [
          @options.fetch(:client_agents, []),
          Meilisearch.qualified_version
        ].flatten.join(';')
      }.compact
    end

    def remove_headers(data, *keys)
      data.delete_if { |k| keys.include?(k) }
    end

    def send_request(http_method, relative_path, config:)
      attempts = 0
      retry_multiplier = config.dig(:options, :retry_multiplier)
      max_retries = config.dig(:options, :max_retries)
      request_config = http_config(config[:query_params], config[:body], config[:options], config[:headers])

      begin
        response = http_method.call(@base_url + relative_path, request_config)
      rescue Errno::ECONNREFUSED, Errno::EPIPE => e
        raise CommunicationError, e.message
      rescue URI::InvalidURIError => e
        raise CommunicationError, "Client URL missing scheme/protocol. Did you mean https://#{@base_url}" unless @base_url =~ %r{^\w+://}

        raise e
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        attempts += 1
        raise TimeoutError, e.message unless attempts <= max_retries && safe_to_retry?(config[:method_type], e)

        sleep(retry_multiplier**attempts)

        retry
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

    # Ensures the only retryable error is a timeout didn't reached the server
    def safe_to_retry?(method_type, error)
      method_type == :get || ([:post, :put, :patch, :delete].include?(method_type) && error.is_a?(Net::OpenTimeout))
    end
  end
end
