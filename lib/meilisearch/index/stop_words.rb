# frozen_string_literal: true

module MeiliSearch
  class Index < HTTPRequest
    module StopWords
      def stop_words
        http_get "/indexes/#{@uid}/stop-words"
      end
      alias_method :get_stop_words, :stop_words

      def add_stop_words(stop_words)
        if stop_words.is_a?(Array)
          http_patch "/indexes/#{@uid}/stop-words", stop_words
        else
          http_patch "/indexes/#{@uid}/stop-words", [stop_words]
        end
      end

      def delete_stop_words(stop_words)
        if stop_words.is_a?(Array)
          http_post "/indexes/#{@uid}/stop-words", stop_words
        else
          http_post "/indexes/#{@uid}/stop-words", [stop_words]
        end
      end
    end
  end
end
