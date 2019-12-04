# frozen_string_literal: true

module MeiliSearch
  class Index < HTTPRequest
    module Documents

      def document(document_uid)
        http_get "/indexes/#{@uid}/documents/#{document_uid}"
      end
      alias_method :get_document,     :document
      alias_method :get_one_document, :document

      def documents(options = {})
        http_get "/indexes/#{@uid}/documents", options
      end
      alias_method :get_documents,     :documents
      alias_method :get_all_documents, :documents

      def add_documents(documents)
        documents = [ documents ] if documents.is_a?(Hash)
        http_post "/indexes/#{@uid}/documents", documents
      end
      alias_method :update_documents,           :add_documents
      alias_method :update_or_update_documents, :add_documents

      def clear_documents
        http_delete "/indexes/#{@uid}/documents"
      end
      alias_method :clear_all_documents, :clear_documents

      def delete_documents(documents_uids)
        if documents_uids.is_a?(Array)
          http_post "/indexes/#{@uid}/documents/delete", documents_uids
        else
          delete_document(documents_uids)
        end
      end
      alias_method :delete_multiple_documents, :delete_documents

      def delete_document(document_uid)
        http_delete "/indexes/#{@uid}/documents/#{document_uid}"
      end
      alias_method :delete_one_document, :delete_document
    end
  end
end
