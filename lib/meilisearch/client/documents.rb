# frozen_string_literal: true

module MeiliSearch
  class Client
    module Documents
      def add_documents(index_name, documents)
        documents.each_slice(1000).map do |slice|
          post "/indexes/#{index_name}/documents", slice
        end
      end

      def document(index_name, document_uid)
        get "/indexes/#{index_name}/documents/#{document_uid}"
      end

      def get_all_documents(index_name)
        get "/indexes/#{index_name}/documents"
      end

      def batch_documents
        raise NotImplementedError
      end

      def update_documents
        raise NotImplementedError
      end

      def delete_one_document(index_name, document_uid)
        delete "/indexes/#{index_name}/documents/#{document_uid}"
      end

      def delete_multiple_documents(index_name, document_uids)
        post "/indexes/#{index_name}/documents/delete", document_uids
      end

      def clear_all_documents(index_name)
        delete "/indexes/#{index_name}/documents"
      end
    end
  end
end
