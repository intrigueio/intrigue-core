module Intrigue
  module Model
    class TaskResult
      include DataMapper::Resource

      belongs_to :base_entity, 'Intrigue::Model::Entity'
      belongs_to :logger, 'Intrigue::Model::Logger'

      has n, :entities

      belongs_to :scan_result, :required => false

      property :id, Serial
      property :name, String
      property :task_name, String
      property :timestamp_start, DateTime
      property :timestamp_end, DateTime
      property :options, Object, :default => [] #StringArray
      property :complete, Boolean, :default => false
      property :entity_count, Integer, :default => 0

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

      def export_csv
        "#{@task_name},#{self.base_entity.name},#{self.entities.map{|x| x.type + "#" + x.name }.join(";")}\n"
      end

      def export_hash
        {
          "id" => @id,
          "name" => @name,
          "task_name" => @task_name,
          "timestamp_start" => @timestamp_start,
          "timestamp_end" => @timestamp_end,
          "options" => @options,
          "complete" => @complete,
          "base_entity" => self.base_entity.export_hash,
          "entity_count" => @entity_count,
          "entities" => self.entities.map{ |x| x.export_hash },
          "log" => self.logger.full_log
        }
      end

      def export_json
        export_hash.to_json
      end
    end
  end
end
