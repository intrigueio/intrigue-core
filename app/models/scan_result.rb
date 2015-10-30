module Intrigue
  module Model

    class ScanResult
      include DataMapper::Resource
      include Intrigue::Model::Logger

      has 1, :entity
      has n, :task_results
      has n, :entities

      property :id, Serial
      property :name, String
      property :depth, Integer
      property :scan_type, String
      property :options, Object
      property :complete, Boolean
      property :full_log, Text, :length => 5000000

      property :timestamp_start, DateTime
      property :timestamp_end, DateTime

      property :entity_count, Integer
      property :filter_strings, Text

      before :create, :configure

      def configure
        #attribute_set :options, []
        #attribute_set :full_log, ""
      end

      def add_task_result(task_result)
        @task_results << task_result
        save
      true
      end

      def add_entity(entity)

        return false if has_entity? entity

        entity_count = 0 unless entity_count

        self.entities << entity
        entity_count += 1
      end

      # Matches based on type and the attribute "name"
      def has_entity? entity
        false
      end
=begin
      def from_json(json)
        begin
          x = JSON.parse(json)
          @id = x["id"]
          @complete = x["complete"]
          @depth = x["depth"]
          @scan_type = x["scan_type"]
          @name = x["name"]
          @timestamp_start = x["timestamp_start"]
          @timestamp_end = x["timestamp_end"]
          @filter_strings = x["filter_strings"]
          @entity = Entity.get(x["entity_id"])
          @task_results = x["task_result_ids"].map{|y| TaskResult.get y } if x["task_result_ids"]
          @entities = x["entity_ids"].map{|y| Entity.get y } if x["entity_ids"]
          @entity_count = x["entity_count"]
          @log = ScanResultLog.get x["id"]
        rescue JSON::ParserError => e
          return nil
        end
      end
=end
      def to_s
        to_json
      end

      def to_hash
        {
          "id" => @id,
          "name" => @name,
          "scan_type" => @scan_type,
          "depth" => @depth,
          "complete" => @complete,
          "timestamp_start" => @timestamp_start,
          "timestamp_end" => @timestamp_end,
          "filter_strings" => @filter_strings,
          "entity_id" => @entity.id,
          "entity_count" => @entity_count,
          "task_result_ids" => @task_results.map{|y| y.id },
          "entity_ids" => @entities.map {|y| y.id },
          "options" => @options,
          "log" => @log.to_text
        }
      end

      def to_json
        to_hash.to_json
      end

      ###
      ### Export!
      ###

      def export_hash
        {
          "id" => @id,
          "name" => @name,
          "scan_type" => @scan_type,
          "depth" => @depth,
          "complete" => @complete,
          "timestamp_start" => @timestamp_start,
          "timestamp_end" => @timestamp_end,
          "filter_strings" => @filter_strings,
          "entity_id" => @entity.to_s,
          "entity_count" => @entity_count,
          "task_result_ids" => @task_results.map{|y| TaskResult.get(y).export_hash },
          "entity_ids" => @entities.map {|y| Entity.get(y).to_s },
          "options" => @options,
          "log" => @log.to_s
        }
      end

      def export_json
        export_hash.to_json
      end

    end
  end
end
