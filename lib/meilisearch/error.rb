# frozen_string_literal: true

module MeiliSearch
  class Error < StandardError
  end

  class ApiError < Error
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
      @http_code = http_code
      @http_message = http_message
      @http_body = parse_body(http_body)
      @ms_code = @http_body['code']
      @ms_type = @http_body['type']
      @ms_message = @http_body.fetch('message', 'MeiliSearch API has not returned any error message')
      @ms_link = @http_body.fetch('link', '<no documentation link found>')
      @message = "#{http_code} #{http_message} - #{@ms_message}. See #{ms_link}."
      super(details)
    end

    def parse_body(http_body)
      if http_body.respond_to?(:to_hash)
        http_body.to_hash
      elsif http_body.respond_to?(:to_str)
        JSON.parse(http_body.to_str)
      else
        {}
      end
    rescue JSON::ParserError
      # We might receive a JSON::ParserError when, for example, MeiliSearch is running behind
      # some proxy (ELB or Nginx, for example), and the request timeouts, returning us
      # a raw HTML body instead of a JSON as we were expecting
      { 'message' => "The server has not returned a valid JSON HTTP body: #{http_body}" }
    end

    def details
      "MeiliSearch::ApiError - code: #{@ms_code} - type: #{ms_type} - message: #{@ms_message} - link: #{ms_link}"
    end
  end

  class CommunicationError < Error
    attr_reader :message

    def initialize(message)
      @message = "An error occurred while trying to connect to the MeiliSearch instance: #{message}"
      super(@message)
    end
  end

  class TimeoutError < Error
    attr_reader :message

    def initialize(message = nil)
      @message = "The request was not processed in the expected time. #{message}"
      super(@message)
    end
  end

  class InvalidDocumentId < Error
    attr_reader :message

    def initialize(message = nil)
      @message = "The document id is invalid. #{message}"
      super(@message)
    end
  end

  module TenantToken
    class ExpireOrInvalidSignature < MeiliSearch::Error; end
    class InvalidApiKey < MeiliSearch::Error; end
    class InvalidSearchRules < MeiliSearch::Error; end
  end
end
