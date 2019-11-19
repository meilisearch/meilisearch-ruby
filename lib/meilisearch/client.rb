# frozen_string_literal: true

require 'httparty'

require 'meilisearch/error'
require 'meilisearch/client/keys'
require 'meilisearch/client/stats'
require 'meilisearch/client/health'
require 'meilisearch/client/indexes'
require 'meilisearch/client/documents'
require 'meilisearch/client/prepare'

module MeiliSearch
  class Client
    include HTTParty

    include MeiliSearch::Client::Keys
    include MeiliSearch::Client::Stats
    include MeiliSearch::Client::Health
    include MeiliSearch::Client::Indexes
    include MeiliSearch::Client::Documents
    include MeiliSearch::Client::Prepare

    def initialize(url, api_key = nil)
      # api_key is is for basic api authorization
      @headers = {}
      @headers['X-Meili-Api-Key'] = api_key if api_key
      @headers['Content-Type'] = 'application/json'
      @base_url = url
    end

    def get(path = '', query = {})
      response = self.class.get(
        (@base_url + path),
        query: query,
        headers: @headers
      )
      validate(response)
    end

    def post(path = '', body = {})
      response = self.class.post(
        (@base_url + path),
        body: body.to_json,
        headers: @headers
      )
      validate(response)
    end

    def delete(path = '', body = {})
      response = self.class.delete(
        (@base_url + path),
        body: body.to_json,
        headers: @headers
      )
      validate(response)
    end

    def put(path = '', body = {})
      response = self.class.put(
        (@base_url + path),
        body: body.to_json,
        headers: @headers
      )
      validate(response)
    end

    private

    def validate(response)
      unless response.success?
        raise ClientError.new(response.message, response.code)
      end

      response.parsed_response
    end
  end
end
