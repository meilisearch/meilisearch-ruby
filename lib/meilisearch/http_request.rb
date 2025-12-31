# frozen_string_literal: true

require 'http'
require 'meilisearch/error'

module Meilisearch
  # Handles HTTP communication with Meilisearch server.
  #
  # Thread Safety Note:
  # When using persistent connections (persistent: true), each Client instance
  # maintains its own HTTP connection. In multi-threaded environments (Puma, Sidekiq),
  # create a separate Client instance per thread rather than sharing one across threads.
  class HTTPRequest
    attr_reader :options, :headers

    DEFAULT_OPTIONS = {
      timeout: 10,
      max_retries: 2,
      retry_multiplier: 1.2,
      convert_body?: true,
      persistent: false
    }.freeze

    # Sentinel value to distinguish "no body passed" from "body is nil"
    NO_BODY = Object.new.freeze

    def initialize(url, api_key = nil, options = {})
      @base_url = url
      @api_key = api_key
      @options = DEFAULT_OPTIONS.merge(options)
      @headers = build_default_headers
      @http_client = build_http_client
    end

    def http_get(relative_path = '', query_params = {}, options = {})
      send_request(:get, relative_path, query_params: query_params, options: options)
    end

    def http_post(relative_path = '', body = NO_BODY, query_params = nil, options = {})
      send_request(:post, relative_path, body: body, query_params: query_params, options: options)
    end

    def http_put(relative_path = '', body = NO_BODY, query_params = nil, options = {})
      send_request(:put, relative_path, body: body, query_params: query_params, options: options)
    end

    def http_patch(relative_path = '', body = NO_BODY, query_params = nil, options = {})
      send_request(:patch, relative_path, body: body, query_params: query_params, options: options)
    end

    def http_delete(relative_path = '', query_params = nil, options = {})
      send_request(:delete, relative_path, query_params: query_params, options: options)
    end

    private

    def build_default_headers
      {
        'Content-Type' => 'application/json',
        'Authorization' => ("Bearer #{@api_key}" unless @api_key.nil?),
        'User-Agent' => [
          @options.fetch(:client_agents, []),
          Meilisearch.qualified_version
        ].flatten.join(';')
      }.compact
    end

    def build_http_client
      client = HTTP.headers(@headers).timeout(@options[:timeout])
      @options[:persistent] ? client.persistent(@base_url) : client
    end

    def send_request(method, relative_path, body: NO_BODY, query_params: nil, options: {})
      merged_options = @options.merge(options)
      url = @options[:persistent] ? relative_path : @base_url + relative_path
      request_options = build_request_options(body, query_params, merged_options, options)

      execute_request(method, url, request_options, merged_options)
    end

    def execute_request(method, url, request_options, merged_options)
      attempts = 0

      begin
        response = @http_client.public_send(method, url, request_options)
        validate_response(response)
      rescue Errno::ECONNREFUSED, Errno::EPIPE, IOError, HTTP::ConnectionError => e
        raise CommunicationError, e.message
      rescue HTTP::TimeoutError => e
        attempts += 1
        raise TimeoutError, e.message unless can_retry?(attempts, merged_options, method, e)

        sleep(merged_options[:retry_multiplier]**attempts)
        retry
      rescue HTTP::Request::UnsupportedSchemeError, Addressable::URI::InvalidURIError, URI::InvalidURIError => e
        raise_invalid_uri_error(e)
      end
    end

    def can_retry?(attempts, options, method, error)
      attempts <= options[:max_retries] && safe_to_retry?(method, error)
    end

    def build_request_options(body, query_params, merged_options, override_options)
      request_opts = {}
      request_opts[:params] = query_params if query_params&.any?

      unless body.equal?(NO_BODY)
        # http.rb's json option doesn't handle nil properly (sends empty body)
        # so we manually serialize to JSON string when convert_body? is true
        request_opts[:body] = merged_options[:convert_body?] ? body.to_json : body
      end

      request_opts[:headers] = override_options[:headers] if override_options[:headers]

      request_opts
    end

    def validate_response(response)
      raise ApiError.new(response.status.code, response.status.reason, response.body.to_s) unless response.status.success?

      parse_response_body(response)
    end

    def parse_response_body(response)
      body = response.body.to_s
      return nil if body.nil? || body.empty?

      JSON.parse(body)
    rescue JSON::ParserError
      body
    end

    def raise_invalid_uri_error(error)
      raise CommunicationError, "Client URL missing scheme/protocol. Did you mean https://#{@base_url}" unless @base_url =~ %r{^\w+://}

      raise CommunicationError, error.message
    end

    # Ensures the only retryable error is a timeout that didn't reach the server (connect timeout)
    def safe_to_retry?(method, error)
      method == :get || ([:post, :put, :patch, :delete].include?(method) && error.is_a?(HTTP::ConnectTimeoutError))
    end
  end
end
