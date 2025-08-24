# frozen_string_literal: true

require 'net/http'
require 'json'

module ExperimentalFeatureHelpers
  def enable_edit_documents_by_function(toggle)
    configure_feature('editDocumentsByFunction', toggle)
  end

  def enable_composite_embedders(toggle)
    configure_feature('compositeEmbedders', toggle)
  end

  private

  # @param [String] attribute_to_toggle
  # @param [Boolean] toggle
  def configure_feature(attribute_to_toggle, toggle)
    uri = URI("http://#{ENV.fetch('MEILISEARCH_URL', 'localhost')}")
    uri.path = '/experimental-features'
    uri.port = ENV.fetch('MEILISEARCH_PORT', '7700')

    req = Net::HTTP::Patch.new(uri)
    req.body = { attribute_to_toggle => toggle }.to_json
    req.content_type = 'application/json'
    req['Authorization'] = "Bearer #{MASTER_KEY}"

    Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
  end
end
