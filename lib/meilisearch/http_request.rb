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
        (@base_url + path),
        query: query,
        headers: @headers
      )
      validate(response)
    end

    def http_post(path = '', body = nil)
      if body.nil?
        response = self.class.post(
          (@base_url + path),
          headers: @headers
        )
      else
        response = self.class.post(
          (@base_url + path),
          body: body.to_json,
          headers: @headers
        )
      end
      validate(response)
    end

    def http_put(path = '', body = {})
      response = self.class.put(
        (@base_url + path),
        body: body.to_json,
        headers: @headers
      )
      validate(response)
    end

    def http_delete(path = '')
      response = self.class.delete(
        (@base_url + path),
        headers: @headers
      )
      validate(response)
    end

    private

    def validate(response)
      unless response.success?
        raise HTTPError.new(response.code, response.message, response.body)
      end
      response.parsed_response
    end
  end
end
