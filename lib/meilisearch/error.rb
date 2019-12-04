# frozen_string_literal: true

module MeiliSearch
  class MeiliSearchError < StandardError; end
  class IndexIdentifierError < MeiliSearchError; end

  class HTTPError < MeiliSearchError

    attr_reader :status
    attr_reader :message
    attr_reader :http_body
    attr_reader :http_body_message
    attr_reader :details

    alias :code         :status
    alias :body         :http_body
    alias :body_message :http_body_message

    def initialize(status, message, http_body, details = nil)
      @status = status
      unless http_body.nil? || http_body.empty?
        @http_body = JSON.parse(http_body)
        @http_body_message = @http_body['message']
      end
      @message = message.capitalize
      @message = "#{@message} - #{@http_body_message.capitalize}" unless @http_body_message.nil?
      @details = details
    end

    def to_s
      final_message = @details.nil? ? @message : "#{@message}. #{@details}"
      "#{@status}: #{final_message}."
    end
  end
end
