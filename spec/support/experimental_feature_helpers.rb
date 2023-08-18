# frozen_string_literal: true

require 'net/http'
require 'json'

module ExperimentalFeatureHelpers
  def enable_score_details(toggle)
    uri = URI("http://#{ENV.fetch('MEILISEARCH_URL', 'localhost')}")
    uri.path = '/experimental-features'
    uri.port = ENV.fetch('MEILISEARCH_PORT', '7700')

    req = Net::HTTP::Patch.new(uri)
    req.body = { scoreDetails: toggle }.to_json
    req.content_type = 'application/json'
    req['Authorization'] = "Bearer #{MASTER_KEY}"

    Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
  end
end
