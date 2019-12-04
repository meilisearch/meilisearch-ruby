# frozen_string_literal: true

module MeiliSearch
  class Index < HTTPRequest
    module Stats
      def stats
        http_get "/stats/#{@uid}"
      end

      def number_of_documents
        stats['numberOfDocuments']
      end

      def is_indexing?
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
