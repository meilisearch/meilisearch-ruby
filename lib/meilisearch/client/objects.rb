# frozen_string_literal: true

module MeiliSearch
  class Client
    module Objects
      def add_objects(index_name, objects)
        if objects.size <= 1000
          post "/indexes/#{index_name}/objects", objects
        else
          objects.each_slice(1000) do |slice|
            post "/indexes/#{index_name}/objects", slice
          end
        end
      end

      def object(index_name, object_identifier)
        get "/indexes/#{index_name}/objects/#{object_identifier}"
      end

      def browse(index_name)
        get "/indexes/#{index_name}/objects"
      end

      def batch_objects
        raise NotImplementedError
      end

      def update_objects
        raise NotImplementedError
      end

      def delete_objects(index_name, object_ids)
        delete "/indexes/#{index_name}/objects", object_ids
      end
    end
  end
end
