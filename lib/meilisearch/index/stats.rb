# frozen_string_literal: true

module MeiliSearch
  class Index < HTTPRequest
    module Stats
      def stats
        http_get "/indexes/#{@uid}/stats"
      end

      def number_of_documents
        stats['numberOfDocuments']
      end

      def indexing?
        stats['isIndexing']
      end

      def last_update
        stats['lastUpdate']
      end

      def fields_frequency
        stats['fieldsFrequency']
      end
    end
  end
end
