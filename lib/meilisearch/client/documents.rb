# frozen_string_literal: true

module MeiliSearch
  class Client
    module Documents
      def add_documents(index_name, documents)
        documents.each_slice(1000) do |slice|
          post "/indexes/#{index_name}/documents", slice
        end
      end

      def document(index_name, document_identifier)
        get "/indexes/#{index_name}/documents/#{document_identifier}"
      end

      def browse(index_name)
        get "/indexes/#{index_name}/documents"
      end

      def batch_documents
        raise NotImplementedError
      end

      def update_documents
        raise NotImplementedError
      end

      def delete_documents(index_name, document_ids)
        delete "/indexes/#{index_name}/documents", document_ids
      end
    end
  end
end
