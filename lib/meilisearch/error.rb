# frozen_string_literal: true

module MeiliSearch
  class MeiliSearchError < StandardError; end

  class ClientError < MeiliSearchError
    attr_reader :code
    attr_reader :msg

    def initialize(message = nil, code = nil)
      @code = code
      @msg = message
    end

    def message
      if code.nil?
        @msg
      else
        "#{@code} - #{@msg}"
      end
    end
  end
end
