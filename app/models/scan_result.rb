module Intrigue
  module Model
    class ScanResult
      include DataMapper::Resource

      belongs_to :base_entity, 'Intrigue::Model::Entity'
      belongs_to :logger, 'Intrigue::Model::Logger'

      has n, :task_results
      has n, :entities

      property :id, Serial
      property :name, String
      property :depth, Integer
      property :scan_type, String
      property :options, Object, :default => []
      property :complete, Boolean, :default => false

      property :timestamp_start, DateTime
      property :timestamp_end, DateTime

      property :entity_count, Integer, :default => 0
      property :filter_strings, Text, :default => ""

      def add_task_result(task_result)
        @task_results << task_result
        save
      true
      end

      def add_entity(entity)
        return false if has_entity? entity
        attribute_set(:entity_count, @entity_count + 1)
        self.entities << entity
        save
      true
      end

      # Matches based on type and the attribute "name"
      def has_entity? entity
        return true if (self.entities.select {|e| e.match? entity}).length > 0
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
          #"base_entity" => @base_entity.export_hash,
          "entity_count" => @entity_count,
          #"task_results" => @task_results.map{|y| TaskResult.get(y).export_hash },
          #"entities" => @entities.map {|y| Entity.get(y).export_hash },
          "options" => @options,
          #"log" => @logger.full_log
        }
      end

      def export_json
        export_hash.to_json
      end

    end
  end
end
