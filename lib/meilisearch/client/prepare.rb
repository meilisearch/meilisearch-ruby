# frozen_string_literal: true

module MeiliSearch
  class Client < HTTPRequest
    module Prepare
      def rollout
        http_put '/prepare/rollout'
      end
    end
  end
end
