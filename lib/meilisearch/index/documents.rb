# frozen_string_literal: true

module Meilisearch
  class Index
    # Documents are objects composed of fields that can contain any type of valid JSON data.
    # @see https://www.meilisearch.com/docs/learn/getting_started/documents Learn more about documents
    module Documents
      # Get a document, optionally limiting fields.
      #
      # @param document_id [String, Integer] The ID of the document to fetch
      # @param fields [nil, Array<Symbol>] Fields to fetch from the document, defaults to all
      # @return [nil, Hash{String => Object}] The requested document.
      # @see https://www.meilisearch.com/docs/reference/api/documents#get-one-document Meilisearch API Reference
      def document(document_id, fields: nil)
        encode_document = URI.encode_www_form_component(document_id)
        body = { fields: fields&.join(',') }.compact

        http_get("/indexes/#{@uid}/documents/#{encode_document}", body)
      end
      alias get_document document
      alias get_one_document document

      # Retrieve documents from a index.
      #
      # @param options [Hash{Symbol => Object}] The hash options used to refine the selection (default: {}):
      #           :limit  - Number of documents to return (optional).
      #           :offset - Number of documents to skip (optional).
      #           :fields - Array of document attributes to show (optional).
      #           :filter - Filter queries by an attribute's value.
      #                     Available ONLY with Meilisearch v1.2 and newer (optional).
      #           :sort   - A list of attributes written as an array or as a comma-separated string (optional)
      #           :ids    - Array of ids to be retrieved (optional)
      #
      # @return [Hash{String => Object}] The documents results object.
      # @see https://www.meilisearch.com/docs/reference/api/documents#get-documents-with-post Meilisearch API Reference
      def documents(options = {})
        Utils.version_error_handler(__method__) do
          if options.key?(:filter)
            http_post "/indexes/#{@uid}/documents/fetch", Utils.filter(options, [:limit, :offset, :fields, :filter, :sort, :ids])
          else
            http_get "/indexes/#{@uid}/documents", Utils.parse_query(options, [:limit, :offset, :fields, :sort, :ids])
          end
        end
      end
      alias get_documents documents

      # Add documents to an index.
      #
      # Documents that already exist in the index are overwritten, with missing fields removed. Identitiy is checked by the value of the primary key field.
      #
      #   client.index('movies').add_documents([
      #     {
      #      id: 287947,
      #      title: 'Shazam',
      #      poster: 'https://image.tmdb.org/t/p/w1280/xnopI5Xtky18MPhK40cZAGAOVeV.jpg',
      #      overview: 'A boy is given the ability to become an adult superhero in times of need with a single magic word.',
      #      release_date: '2019-03-23'
      #     }
      #   ])
      #
      # @param documents [Array<Hash{Object => Object>}] The documents to be added.
      # @param primary_key [String] The name of the primary key field, auto inferred if missing.
      #
      # @return [Models::Task] The async task that adds the documents.
      # @see https://www.meilisearch.com/docs/reference/api/documents#add-or-replace-documents Meilisearch API Reference
      def add_documents(documents, primary_key = nil)
        documents = [documents] if documents.is_a?(Hash)
        response = http_post "/indexes/#{@uid}/documents", documents, { primaryKey: primary_key }.compact

        Models::Task.new(response, task_endpoint)
      end
      alias replace_documents add_documents
      alias add_or_replace_documents add_documents

      # Synchronous version of {#add_documents}.
      #
      # @deprecated
      #   use {Models::Task#await} on task returned from {#add_documents}
      #
      #     index.add_documents(...).await
      #
      # Waits for the task to be achieved with a busy loop, be careful when using it.
      def add_documents!(documents, primary_key = nil)
        Utils.soft_deprecate(
          'Index#add_documents!',
          'index.add_documents(...).await'
        )

        add_documents(documents, primary_key).await
      end
      alias replace_documents! add_documents!
      alias add_or_replace_documents! add_documents!

      # Add or replace documents from a JSON string.
      #
      # Documents that already exist in the index are overwritten, with missing fields removed. Identitiy is checked by the value of the primary key field.
      #
      # @param documents [String] JSON document that includes your documents.
      # @param primary_key [String] The name of the primary key field, auto inferred if missing.
      #
      # @return [Models::Task] The async task that adds the documents.
      def add_documents_json(documents, primary_key = nil)
        options = { convert_body?: false }
        response = http_post "/indexes/#{@uid}/documents", documents, { primaryKey: primary_key }.compact, options

        Models::Task.new(response, task_endpoint)
      end
      alias replace_documents_json add_documents_json
      alias add_or_replace_documents_json add_documents_json

      # Add or replace documents from a NDJSON string.
      #
      # Documents that already exist in the index are overwritten, with missing fields removed. Identitiy is checked by the value of the primary key field.
      # Newline delimited JSON is a JSON specification that is easier to stream.
      #
      # @param documents [String] JSON document that includes your documents.
      # @param primary_key [String] The name of the primary key field, auto inferred if missing.
      #
      # @return [Models::Task] The async task that adds the documents.
      #
      # @see https://github.com/ndjson/ndjson-spec NDJSON spec
      def add_documents_ndjson(documents, primary_key = nil)
        options = { headers: { 'Content-Type' => 'application/x-ndjson' }, convert_body?: false }
        response = http_post "/indexes/#{@uid}/documents", documents, { primaryKey: primary_key }.compact, options

        Models::Task.new(response, task_endpoint)
      end
      alias replace_documents_ndjson add_documents_ndjson
      alias add_or_replace_documents_ndjson add_documents_ndjson

      # Add or replace documents from a CSV string.
      #
      # Documents that already exist in the index are overwritten, with missing fields removed. Identitiy is checked by the value of the primary key field.
      # CSV text is delimited by commas by default but Meilisearch allows specifying custom delimeters.
      #
      # @param documents [String] JSON document that includes your documents.
      # @param primary_key [String] The name of the primary key field, auto inferred if missing.
      # @param delimiter [String] The delimiter character in your CSV text.
      #
      # @return [Models::Task] The async task that adds the documents.
      def add_documents_csv(documents, primary_key = nil, delimiter = nil)
        options = { headers: { 'Content-Type' => 'text/csv' }, convert_body?: false }

        response = http_post "/indexes/#{@uid}/documents", documents, {
          primaryKey: primary_key,
          csvDelimiter: delimiter
        }.compact, options

        Models::Task.new(response, task_endpoint)
      end
      alias replace_documents_csv add_documents_csv
      alias add_or_replace_documents_csv add_documents_csv

      # Add documents to an index.
      #
      # Documents that already exist in the index are updated, with missing fields ignored. Identitiy is checked by the value of the primary key field.
      #
      # @param documents [Array<Hash{Object => Object>}] The documents to be added.
      # @param primary_key [String] The name of the primary key field, auto inferred if missing.
      #
      # @return [Models::Task] The async task that adds the documents.
      # @see https://www.meilisearch.com/docs/reference/api/documents#add-or-replace-documents Meilisearch API Reference
      def update_documents(documents, primary_key = nil)
        documents = [documents] if documents.is_a?(Hash)
        response = http_put "/indexes/#{@uid}/documents", documents, { primaryKey: primary_key }.compact

        Models::Task.new(response, task_endpoint)
      end
      alias add_or_update_documents update_documents

      # Add or update documents from a JSON string.
      #
      # Documents that already exist in the index are updated, with missing fields ignored. Identitiy is checked by the value of the primary key field.
      #
      # @param documents [String] JSON document that includes your documents.
      # @param primary_key [String] The name of the primary key field, auto inferred if missing.
      #
      # @return [Models::Task] The async task that adds the documents.
      def update_documents_json(documents, primary_key = nil)
        options = { convert_body?: false }
        response = http_put "/indexes/#{@uid}/documents", documents, { primaryKey: primary_key }.compact, options

        Models::Task.new(response, task_endpoint)
      end
      alias add_or_update_documents_json update_documents_json

      # Add or update documents from a NDJSON string.
      #
      # Documents that already exist in the index are updated, with missing fields ignored. Identitiy is checked by the value of the primary key field.
      # Newline delimited JSON is a JSON specification that is easier to stream.
      #
      # @param documents [String] JSON document that includes your documents.
      # @param primary_key [String] The name of the primary key field, auto inferred if missing.
      #
      # @return [Models::Task] The async task that adds the documents.
      #
      # @see https://github.com/ndjson/ndjson-spec NDJSON spec
      def update_documents_ndjson(documents, primary_key = nil)
        options = { headers: { 'Content-Type' => 'application/x-ndjson' }, convert_body?: false }
        response = http_put "/indexes/#{@uid}/documents", documents, { primaryKey: primary_key }.compact, options

        Models::Task.new(response, task_endpoint)
      end
      alias add_or_update_documents_ndjson update_documents_ndjson

      # Add or update documents from a CSV string.
      #
      # Documents that already exist in the index are updated, with missing fields ignored. Identitiy is checked by the value of the primary key field.
      # CSV text is delimited by commas by default but Meilisearch allows specifying custom delimeters.
      #
      # @param documents [String] JSON document that includes your documents.
      # @param primary_key [String] The name of the primary key field, auto inferred if missing.
      # @param delimiter [String] The delimiter character in your CSV text.
      #
      # @return [Models::Task] The async task that adds the documents.
      def update_documents_csv(documents, primary_key = nil, delimiter = nil)
        options = { headers: { 'Content-Type' => 'text/csv' }, convert_body?: false }

        response = http_put "/indexes/#{@uid}/documents", documents, {
          primaryKey: primary_key,
          csvDelimiter: delimiter
        }.compact, options

        Models::Task.new(response, task_endpoint)
      end
      alias add_or_update_documents_csv add_documents_csv

      # Batched version of {#update_documents_ndjson}
      #
      # @param documents [String] JSON document that includes your documents.
      # @param batch_size [Integer] The number of documents to update at a time.
      # @param primary_key [String] The name of the primary key field, auto inferred if missing.
      #
      # @return [Array<Models::Task>] An array of tasks for each batch.
      #
      # @see https://github.com/ndjson/ndjson-spec NDJSON spec
      def update_documents_ndjson_in_batches(documents, batch_size = 1000, primary_key = nil)
        documents.lines.each_slice(batch_size).map do |batch|
          update_documents_ndjson(batch.join, primary_key)
        end
      end

      # Batched version of {#update_documents_csv}.
      #
      # @param documents [String] JSON document that includes your documents.
      # @param batch_size [Integer] The number of documents to update at a time.
      # @param primary_key [String] The name of the primary key field, auto inferred if missing.
      # @param delimiter [String] The delimiter character in your CSV text.
      #
      # @return [Array<Models::Task>] An array of tasks for each batch.
      def update_documents_csv_in_batches(documents, batch_size = 1000, primary_key = nil, delimiter = nil)
        lines = documents.lines
        heading = lines.first
        lines.drop(1).each_slice(batch_size).map do |batch|
          update_documents_csv(heading + batch.join, primary_key, delimiter)
        end
      end

      # Synchronous version of {#update_documents}.
      #
      # @deprecated
      #   use {Models::Task#await} on task returned from {#update_documents}
      #
      #     index.update_documents(...).await
      #
      # Waits for the task to be achieved with a busy loop, be careful when using it.
      def update_documents!(documents, primary_key = nil)
        Utils.soft_deprecate(
          'Index#update_documents!',
          'index.update_documents(...).await'
        )

        update_documents(documents, primary_key).await
      end
      alias add_or_update_documents! update_documents!

      # Batched version of {#add_documents}.
      #
      # @param documents [String] JSON document that includes your documents.
      # @param batch_size [Integer] The number of documents to update at a time.
      # @param primary_key [String] The name of the primary key field, auto inferred if missing.
      #
      # @return [Array<Models::Task>] An array of tasks for each batch.
      def add_documents_in_batches(documents, batch_size = 1000, primary_key = nil)
        documents.each_slice(batch_size).map do |batch|
          add_documents(batch, primary_key)
        end
      end

      # Batched version of {#add_documents_ndjson}.
      #
      # @param documents [String] JSON document that includes your documents.
      # @param batch_size [Integer] The number of documents to update at a time.
      # @param primary_key [String] The name of the primary key field, auto inferred if missing.
      #
      # @return [Array<Models::Task>] An array of tasks for each batch.
      def add_documents_ndjson_in_batches(documents, batch_size = 1000, primary_key = nil)
        documents.lines.each_slice(batch_size).map do |batch|
          add_documents_ndjson(batch.join, primary_key)
        end
      end

      # Batched version of {#add_documents_csv}.
      #
      # @param documents [String] JSON document that includes your documents.
      # @param batch_size [Integer] The number of documents to update at a time.
      # @param primary_key [String] The name of the primary key field, auto inferred if missing.
      # @param delimiter [String] The delimiter character in your CSV text.
      #
      # @return [Array<Models::Task>] An array of tasks for each batch.
      def add_documents_csv_in_batches(documents, batch_size = 1000, primary_key = nil, delimiter = nil)
        lines = documents.lines
        heading = lines.first
        lines.drop(1).each_slice(batch_size).map do |batch|
          add_documents_csv(heading + batch.join, primary_key, delimiter)
        end
      end

      # Synchronous version of {#add_documents_in_batches}.
      #
      # @deprecated
      #   use {Models::Task#await} on task returned from {#add_documents_in_batches}
      #
      #     index.add_documents_in_batches(...).await
      #
      # Waits for the task to be achieved with a busy loop, be careful when using it.
      def add_documents_in_batches!(documents, batch_size = 1000, primary_key = nil)
        Utils.soft_deprecate(
          'Index#add_documents_in_batches!',
          'index.add_documents_in_batches(...).each(&:await)'
        )

        add_documents_in_batches(documents, batch_size, primary_key).each(&:await)
      end

      # Batched version of {#update_documents}.
      #
      # @param documents [String] JSON document that includes your documents.
      # @param batch_size [Integer] The number of documents to update at a time.
      # @param primary_key [String] The name of the primary key field, auto inferred if missing.
      #
      # @return [Array<Models::Task>] An array of tasks for each batch.
      def update_documents_in_batches(documents, batch_size = 1000, primary_key = nil)
        documents.each_slice(batch_size).map do |batch|
          update_documents(batch, primary_key)
        end
      end

      # Synchronous version of {#update_documents_in_batches}.
      #
      # @deprecated
      #   use {Models::Task#await} on task returned from {#update_documents_in_batches}
      #
      #     index.update_documents_in_batches(...).await
      #
      # Waits for the task to be achieved with a busy loop, be careful when using it.
      def update_documents_in_batches!(documents, batch_size = 1000, primary_key = nil)
        Utils.soft_deprecate(
          'Index#update_documents_in_batches!',
          'index.update_documents_in_batches(...).each(&:await)'
        )

        update_documents_in_batches(documents, batch_size, primary_key).each(&:await)
      end

      # Update documents by function
      #
      # @param options [Hash{String => Object}]
      #
      # @see https://www.meilisearch.com/docs/reference/api/documents#update-documents-with-function Meilisearch API Documentation
      def update_documents_by_function(options)
        response = http_post "/indexes/#{@uid}/documents/edit", options

        Models::Task.new(response, task_endpoint)
      end

      # Delete documents from an index.
      #
      #   index.delete_documents([1, 2, 3, 4])
      #   index.delete_documents({ filter: "age > 10" })
      #
      # @param options [Array<[String, Integer]>, Hash{Symbol => String}] A Hash or an Array containing documents_ids or a hash with filter: key.
      #   filter: - A hash containing a filter that should match documents.
      #             Available ONLY with Meilisearch v1.2 and newer (optional)
      #
      # @return [Models::Task] An object representing the async deletion task.
      def delete_documents(options = {})
        Utils.version_error_handler(__method__) do
          response = if options.is_a?(Hash) && options.key?(:filter)
                       http_post "/indexes/#{@uid}/documents/delete", options
                     else
                       # backwards compatibility:
                       # expect to be a array or/number/string to send alongside as documents_ids.
                       options = [options] unless options.is_a?(Array)

                       http_post "/indexes/#{@uid}/documents/delete-batch", options
                     end

          Models::Task.new(response, task_endpoint)
        end
      end
      alias delete_multiple_documents delete_documents

      # Synchronous version of {#delete_documents}.
      #
      # @deprecated
      #   use {Models::Task#await} on task returned from {#delete_documents}
      #
      #     index.delete_documents(...).await
      #
      # Waits for the task to be achieved with a busy loop, be careful when using it.
      def delete_documents!(documents_ids)
        Utils.soft_deprecate(
          'Index#delete_documents!',
          'index.delete_documents(...).await'
        )

        delete_documents(documents_ids).await
      end
      alias delete_multiple_documents! delete_documents!

      # Delete a single document by id.
      #
      #   index.delete_document(15)
      #
      # @param document_id [String, Integer] The ID of the document to delete.
      #
      # @return [Models::Task] An object representing the async deletion task.
      def delete_document(document_id)
        raise Meilisearch::InvalidDocumentId, 'document_id cannot be empty or nil' if document_id.nil? || document_id.to_s.empty?

        encode_document = URI.encode_www_form_component(document_id)
        response = http_delete "/indexes/#{@uid}/documents/#{encode_document}"

        Models::Task.new(response, task_endpoint)
      end
      alias delete_one_document delete_document

      # Synchronous version of {#delete_document}.
      #
      # @deprecated
      #   use {Models::Task#await} on task returned from {#delete_document}
      #
      #     index.delete_document(...).await
      #
      # Waits for the task to be achieved with a busy loop, be careful when using it.
      def delete_document!(document_id)
        Utils.soft_deprecate(
          'Index#delete_document!',
          'index.delete_document(...).await'
        )

        delete_document(document_id).await
      end
      alias delete_one_document! delete_document!

      # Delete all documents in the index.
      #
      #   index.delete_all_documents
      #
      # @return [Models::Task] An object representing the async deletion task.
      def delete_all_documents
        response = http_delete "/indexes/#{@uid}/documents"
        Models::Task.new(response, task_endpoint)
      end

      # Synchronous version of {#delete_all_documents}.
      #
      # @deprecated
      #   use {Models::Task#await} on task returned from {#delete_all_documents}
      #
      #     index.delete_all_documents(...).await
      #
      # Waits for the task to be achieved with a busy loop, be careful when using it.
      def delete_all_documents!
        Utils.soft_deprecate(
          'Index#delete_all_documents!',
          'index.delete_all_documents(...).await'
        )

        delete_all_documents.await
      end
    end

    include Documents
  end
end
