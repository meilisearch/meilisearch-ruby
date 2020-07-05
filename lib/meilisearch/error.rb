# frozen_string_literal: true

module MeiliSearch
  class TimeoutError < StandardError
    attr_reader :message

    def initialize
      @message = "The enqueued update was not processed in the expected time"
      super(@message)
    end

    def to_s
      "#{@message}."
    end
  end

  class ApiError < StandardError
    attr_reader :http_code      # e.g. 400, 404...
    attr_reader :http_message   # e.g. Bad Request, Not Found...
    attr_reader :http_body      # The response body received from the MeiliSearch API
    attr_reader :code           # The error code given by the MeiliSearch API
    attr_reader :type           # The error type given by the MeiliSearch API
    attr_reader :link           # The documentation link given by the MeiliSearch API
    attr_reader :ms_message     # The error message given by the MeiliSearch API
    attr_reader :message        # The detailed error message of this error class

    alias ms_code code
    alias ms_type type
    alias ms_link link

    def initialize(http_code, http_message, http_body)
      @http_code = http_code
      @http_message = http_message
      unless http_body.nil? || http_body.empty?
        @http_body = JSON.parse(http_body)
        @code = @http_body['errorCode']
        @ms_message = @http_body['message']
        @type = @http_body['errorType']
        @link = @http_body['errorLink']
      end
      @ms_message = @ms_message || 'MeiliSearch API has not returned any error message'
      @link = @link || '<no documentation link found>'
      @message = "#{http_code} #{http_message} - #{@ms_message.capitalize}. See #{link}."
      super(details)
    end

    def details
      "MeiliSearch::ApiError - code: #{@code} - type: #{type} - message: #{@ms_message} - link: #{link}"
    end

  end
end
