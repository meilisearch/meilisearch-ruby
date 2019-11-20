# frozen_string_literal: true

module MeiliSearch
  # This class represents the dataset we can index
  class Dataset
    class NotEnumerable < StandardError; end
    class CannotDetermineHeader < StandardError; end
    class ExtensionNotRecognized < StandardError; end

    attr_accessor :data

    def self.new_from_s3(s3_file)
      filename = s3_file.filename.to_s
      if filename.match?(/.csv$/)
        data = CSV.parse(s3_file.download, headers: true)
      elsif filename.match?(/.json$/)
        data = JSON.parse(s3_file.download)
      else
        raise Dataset::ExtensionNotRecognized
      end
      new(data)
    end

    def initialize(data)
      @data = data
      raise Dataset::NotEnumerable unless enumerable?
    end

    def clean
      encode_to_utf8
      replace_nil_values
      @data
    end

    def headers
      if @data.class == Array
        @data.first.keys
      elsif @data.class == CSV::Table
        @data.headers
      else
        raise CannotDetermineHeader
      end
    end

    def schema
      schema = headers.map do |attribute|
        [attribute, [:indexed, :displayed]]
      end.to_h

      # Find first attribute containing id
      identifier = headers.detect { |attribute| attribute[/id/i] }

      # Then give it the :identifier attribute
      schema[identifier].push :identifier
      schema
    end

    private

    def replace_nil_values
      @data = @data.map do |record|
        record.each do |key, value|
          record[key] = '' if value.nil?
        end
      end
    end

    def encode_to_utf8
      @data = @data.map(&:to_h).map(&:to_utf8)
    end

    def enumerable?
      @data.respond_to? :each
    end
  end
end
