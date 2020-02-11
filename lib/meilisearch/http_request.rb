# frozen_string_literal: true

require 'httparty'
require 'meilisearch/error'

module MeiliSearch
  class HTTPRequest
    include HTTParty

    def initialize(url, api_key = nil)
      @base_url = url
      @api_key = api_key
      @headers = {
        'Content-Type' => 'application/json',
        'X-Meili-API-Key' => api_key
      }.compact
    end

    def http_get(path = '', query = {})
      response = self.class.get(
        @base_url + path,
        query: query,
        headers: @headers, timeout: 1
      )
      validate(response)
    end

    def http_post(path = '', body = nil)
      response = if body.nil?
                   self.class.post(
                     @base_url + path,
                     headers: @headers, timeout: 1
                   )
                 else
                   self.class.post(
                     @base_url + path,
                     body: body.to_json,
                     headers: @headers, timeout: 1
                   )
                 end
      validate(response)
    end

    def http_put(path = '', body = {})
      response = self.class.put(
        @base_url + path,
        body: body.to_json,
        headers: @headers, timeout: 1
      )
      validate(response)
    end

    def http_patch(path = '', body = {})
      response = self.class.patch(
        @base_url + path,
        body: body.to_json,
        headers: @headers, timeout: 1
      )
      validate(response)
    end

    def http_delete(path = '')
      response = self.class.delete(
        @base_url + path,
        headers: @headers, timeout: 1
      )
      validate(response)
    end

    private

    def validate(response)
      raise HTTPError.new(response.code, response.message, response.body) unless response.success?

      response.parsed_response
    end
  end
end
