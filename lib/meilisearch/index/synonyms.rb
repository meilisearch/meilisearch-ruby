# frozen_string_literal: true

module MeiliSearch
  class Index < HTTPRequest
    module Synonyms
      def synonyms_of(synonym)
        encode_synonym = URI.encode_www_form_component(synonym)
        http_get "/indexes/#{@uid}/synonyms/#{encode_synonym}"
      end
      alias get_synonyms_of_one_sequence synonyms_of
      alias get_synonyms_of synonyms_of

      def all_synonyms
        http_get "/indexes/#{@uid}/synonyms"
      end
      alias get_all_synonyms all_synonyms
      alias get_all_sequences all_synonyms

      def add_synonyms(synonyms)
        http_post "/indexes/#{@uid}/synonyms", synonyms
      end

      def add_synonyms_one_way(input, synonyms)
        add_synonyms(input: input, synonyms: synonyms)
      end

      def add_synonyms_multi_way(synonyms)
        add_synonyms(synonyms: synonyms)
      end

      def update_synonym(synonym, new_synonyms)
        encode_synonym = URI.encode_www_form_component(synonym)
        http_put "/indexes/#{@uid}/synonyms/#{encode_synonym}", new_synonyms
      end

      def delete_synonym(synonym)
        encode_synonym = URI.encode_www_form_component(synonym)
        http_delete "/indexes/#{@uid}/synonyms/#{encode_synonym}"
      end
      alias delete_one_synonym delete_synonym

      def batch_write_synonyms(synonyms)
        http_post "/indexes/#{@uid}/synonyms/batch", synonyms
      end

      def clear_synonyms
        http_delete "/indexes/#{@uid}/synonyms"
      end
      alias clear_all_synonyms clear_synonyms
    end
  end
end
