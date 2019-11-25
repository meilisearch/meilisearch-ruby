# frozen_string_literal: true

module MeiliSearch
  class Client
    module Documents
      def add_documents(index_uid, documents)
        documents.each_slice(1000).map do |slice|
          post "/indexes/#{index_uid}/documents", slice
        end
      end

      def document(index_uid, document_uid)
        get "/indexes/#{index_uid}/documents/#{document_uid}"
      end

      def get_all_documents(index_uid)
        get "/indexes/#{index_uid}/documents"
      end

      def batch_documents
        raise NotImplementedError
      end

      def update_documents
        raise NotImplementedError
      end

      def delete_one_document(index_uid, document_uid)
        delete "/indexes/#{index_uid}/documents/#{document_uid}"
      end

      def delete_multiple_documents(index_uid, document_uids)
        post "/indexes/#{index_uid}/documents/delete", document_uids
      end

      def clear_all_documents(index_uid)
        delete "/indexes/#{index_uid}/documents"
      end
    end
  end
end
