# frozen_string_literal: true

module MeiliSearch
  class Index < HTTPRequest
    module Documents
      def document(document_id)
        encode_document = URI.encode_www_form_component(document_id)
        http_get "/indexes/#{@uid}/documents/#{encode_document}"
      end
      alias get_document document
      alias get_one_document document

      def documents(options = {})
        http_get "/indexes/#{@uid}/documents", options
      end
      alias get_documents documents

      def add_documents(documents)
        documents = [documents] if documents.is_a?(Hash)
        http_post "/indexes/#{@uid}/documents", documents
      end
      alias replace_documents add_documents
      alias add_or_replace_documents add_documents

      def update_documents(documents)
        documents = [documents] if documents.is_a?(Hash)
        http_put "/indexes/#{@uid}/documents", documents
      end
      alias add_or_update_documents update_documents

      def clear_documents
        http_delete "/indexes/#{@uid}/documents"
      end
      alias clear_all_documents clear_documents

      def delete_documents(documents_ids)
        if documents_ids.is_a?(Array)
          http_post "/indexes/#{@uid}/documents/delete", documents_ids
        else
          delete_document(documents_ids)
        end
      end
      alias delete_multiple_documents delete_documents

      def delete_document(document_id)
        encode_document = URI.encode_www_form_component(document_id)
        http_delete "/indexes/#{@uid}/documents/#{encode_document}"
      end
      alias delete_one_document delete_document
    end
  end
end
