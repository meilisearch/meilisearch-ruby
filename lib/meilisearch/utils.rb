# frozen_string_literal: true

require 'logger'

module Meilisearch
  module Utils
    SNAKE_CASE = /[^a-zA-Z0-9]+(.)/

    class << self
      attr_writer :logger

      def logger
        @logger ||= Logger.new($stdout)
      end

      def soft_deprecate(subject, replacement)
        logger.warn("[meilisearch-ruby] #{subject} is DEPRECATED, please use #{replacement} instead.")
      end

      def warn_on_unfinished_task(task_uid)
        message = <<~UNFINISHED_TASK_WARNING
          [meilisearch-ruby] Task #{task_uid}'s finished state (succeeded?/failed?/cancelled?) is being checked before finishing.
          [meilisearch-ruby] Tasks in meilisearch are processed in the background asynchronously.
          [meilisearch-ruby] Please use the #finished? method to check if the task is finished or the #await method to wait for the task to finish.
        UNFINISHED_TASK_WARNING

        message.lines.each do |line|
          logger.warn(line)
        end
      end

      def transform_attributes(body)
        case body
        when Array
          body.map { |item| transform_attributes(item) }
        when Hash
          warn_on_non_conforming_attribute_names(body)
          parse(body)
        else
          body
        end
      end

      def filter(original_options, allowed_params = [])
        original_options.transform_keys(&:to_sym).slice(*allowed_params)
      end

      def parse_query(original_options, allowed_params = [])
        only_allowed_params = filter(original_options, allowed_params)

        Utils.transform_attributes(only_allowed_params).then do |body|
          body.transform_values do |v|
            v.respond_to?(:join) ? v.join(',') : v.to_s
          end
        end
      end

      def version_error_handler(method_name)
        yield if block_given?
      rescue Meilisearch::ApiError => e
        message = message_builder(e.http_message, method_name)

        raise Meilisearch::ApiError.new(e.http_code, message, e.http_body)
      rescue StandardError => e
        raise e.class, message_builder(e.message, method_name)
      end

      def warn_on_non_conforming_attribute_names(body)
        return if body.nil?

        non_snake_case = body.keys.grep_v(/^[a-z0-9_]+$/)
        return if non_snake_case.empty?

        message = <<~MSG
          [meilisearch-ruby] Attributes will be expected to be snake_case in future versions.
          [meilisearch-ruby] Non-conforming attributes: #{non_snake_case.join(', ')}
        MSG

        logger.warn(message)
      end

      private

      def parse(body)
        body
          .transform_keys(&:to_s)
          .transform_keys do |key|
            key.include?('_') ? key.downcase.gsub(SNAKE_CASE, &:upcase).gsub('_', '') : key
          end
            .transform_values { |val| transform_attributes(val) }
      end

      def message_builder(current_message, method_name)
        "#{current_message}\nHint: It might not be working because maybe you're not up " \
          "to date with the Meilisearch version that `#{method_name}` call requires."
      end
    end
  end
end
