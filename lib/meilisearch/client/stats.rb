# frozen_string_literal: true

module MeiliSearch
  class Client
    module Stats
      def version
        get '/version'
      end

      def sysinfo
        get '/sys-info'
      end

      def stats
        get '/stats'
      end

      def stats_index(index_uid)
        get "/stats/#{index_uid}"
      end

      def number_of_documents_in_index(index_uid)
        stats_index(index_uid)['numberOfDocuments']
      end

      def index_is_indexing?(index_uid)
        stats_index(index_uid)['isIndexing']
      end

      def index_last_update(index_uid)
        stats_index(index_uid)['lastUpdate']
      end

      def index_fields_frequency(index_uid)
        stats_index(index_uid)['fieldsFrequency']
      end
    end
  end
end
