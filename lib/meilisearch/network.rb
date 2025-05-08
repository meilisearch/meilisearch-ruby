# frozen_string_literal: true

module Meilisearch
  module Network
    def network
      http_get '/network'
    end

    def update_network(new_network)
      new_network = Utils.transform_attributes(new_network)
      http_patch '/network', new_network
    end
  end
end
