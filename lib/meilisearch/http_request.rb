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
      @options = merge_options({
                                 timeout: 1,
                                 max_retries: 0,
                                 headers: build_default_options_headers(api_key),
                                 transform_body?: true
                               }, options)
    end

    def http_get(relative_path = '', query_params = {})
      send_request(
        proc { |path, config| self.class.get(path, config) },
        relative_path,
        query_params: query_params,
        options: remove_options_header(@options, 'Content-Type')
      )
    end

    def http_post(relative_path = '', body = nil, query_params = nil, options = {})
      send_request(
        proc { |path, config| self.class.post(path, config) },
        relative_path,
        query_params: query_params,
        body: body,
        options: merge_options(@options, options)
      )
    end

    def http_put(relative_path = '', body = nil, query_params = nil)
      send_request(
        proc { |path, config| self.class.put(path, config) },
        relative_path,
        query_params: query_params,
        body: body,
        options: @options
      )
    end

    def http_delete(relative_path = '')
      send_request(
        proc { |path, config| self.class.delete(path, config) },
        relative_path,
        options: remove_options_header(@options, 'Content-Type')
      )
    end

    private

    def build_default_options_headers(api_key = nil)
      {
        'Content-Type' => 'application/json',
        'X-Meili-API-Key' => api_key
      }.compact
    end

    def merge_options(default_options, added_options = {})
      default_cloned_headers = default_options[:headers].clone
      merged_options = default_options.merge(added_options)
      merged_options[:headers] = default_cloned_headers.merge(added_options[:headers]) if added_options.key?(:headers)
      merged_options
    end

    def remove_options_header(options, key)
      cloned_options = clone_options(options)
      cloned_options[:headers].tap { |headers| headers.delete(key) }
      cloned_options
    end

    def clone_options(options)
      cloned_options = options.clone
      cloned_options[:headers] = options[:headers].clone
      cloned_options
    end

    SNAKE_CASE = /[^a-zA-Z0-9]+(.)/.freeze

    def send_request(http_method, relative_path, query_params: nil, body: nil, options: {})
      config = http_config(query_params, body, options)
      begin
        response = http_method.call(@base_url + relative_path, config)
      rescue Errno::ECONNREFUSED => e
        raise CommunicationError, e.message
      end
      validate(response)
    end

    def http_config(query_params, body, options)
      body = transform_attributes(body).to_json if options[:transform_body?] == true
      {
        headers: options[:headers],
        query: query_params,
        body: body,
        timeout: options[:timeout],
        max_retries: options[:max_retries]
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
