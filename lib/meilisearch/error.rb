# frozen_string_literal: true

module MeiliSearch
  class ApiError < StandardError
    # :http_code    # e.g. 400, 404...
    # :http_message # e.g. Bad Request, Not Found...
    # :http_body    # The response body received from the MeiliSearch API
    # :ms_code      # The error code given by the MeiliSearch API
    # :ms_type      # The error type given by the MeiliSearch API
    # :ms_link      # The documentation link given by the MeiliSearch API
    # :ms_message   # The error message given by the MeiliSearch API
    # :message      # The detailed error message of this error class

    attr_reader :http_code, :http_message, :http_body, :ms_code, :ms_type, :ms_link, :ms_message, :message

    alias code ms_code
    alias type ms_type
    alias link ms_link

    def initialize(http_code, http_message, http_body)
      get_meilisearch_error_info(http_body) unless http_body.nil? || http_body.empty?
      @http_code = http_code
      @http_message = http_message
      @ms_message ||= 'MeiliSearch API has not returned any error message'
      @ms_link ||= '<no documentation link found>'
      @message = "#{http_code} #{http_message} - #{@ms_message}. See #{ms_link}."
      super(details)
    end

    def get_meilisearch_error_info(http_body)
      @http_body = JSON.parse(http_body)
      @ms_code = @http_body['errorCode']
      @ms_message = @http_body['message']
      @ms_type = @http_body['errorType']
      @ms_link = @http_body['errorLink']
    end

    def details
      "MeiliSearch::ApiError - code: #{@ms_code} - type: #{ms_type} - message: #{@ms_message} - link: #{ms_link}"
    end
  end

  class CommunicationError < StandardError
    attr_reader :message

    def initialize(message)
      @message = "An error occurred while trying to connect to the MeiliSearch instance: #{message}"
      super(@message)
    end
  end

  class TimeoutError < StandardError
    attr_reader :message

    def initialize
      @message = 'The update was not processed in the expected time'
      super(@message)
    end
  end
end
