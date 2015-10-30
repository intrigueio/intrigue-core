module Intrigue
  module Model
    class TaskResult
      include DataMapper::Resource
      include Intrigue::Model::Logger

      has 1, :entity
      has n, :entities

      belongs_to :scan_result, :required => false

      property :id, Serial
      property :name, String
      property :task_name, String
      property :timestamp_start, DateTime
      property :timestamp_end, DateTime
      property :options, Object #StringArray
      property :complete, Boolean
      property :entity_count, Integer
      property :full_log, Text, :length => 5000000

      before :create, :configure

      def configure
        #attribute_set :options, []
        #attribute_set :full_log, ""
      end

      def add_entity(entity)
        return false if has_entity? entity

        entity_count = 0 unless entity_count

        self.entities << entity
        entity_count += 1
      end

      # Matches based on type and the attribute "name"
      def has_entity? entity
        false #self.entities.include? entity
      end
=begin
      def from_json(json)
        begin
          x = JSON.parse(json)
          @id = x["id"]
          @name = x["name"]
          @task_ids = x["task_ids"]
          @timestamp_start = x["timestamp_start"]
          @timestamp_end = x["timestamp_end"]
          @entity = Entity.get x["entity_id"]
          @task_name = x["task_name"]
          @entity_count = x["entity_count"]
          @options = x["options"]
          @entities = x["entity_ids"].map { |y| Entity.get y }
          @complete = x["complete"]
          @log = TaskResultLog.get x["id"]
        rescue JSON::ParserError => e
          return nil
        end
      end
=end
      #def to_s
      #  to_json
      #end
=begin
      def to_hash
        {
          "id" => @id,
          "name" => @name,
          "task_name" => @task_name,
          "timestamp_start" => @timestamp_start,
          "timestamp_end" => @timestamp_end,
          "entity_id" => entity_id,
          "options" => @options,
          "complete" => @complete,
          "entity_count" => @entity_count,
          "entity_ids" => @entities.map{ |x| x.id if x},
          "log" => @log.to_text
        }
      end
=end
      #def to_json
      #  to_hash.to_json
      #end

      ###
      ### Export!
      ###

      def export_csv
        "#{@task_name},#{@entity.name},#{@entities.map{|x| x.type + "#" + x.attributes["name"] }.join(";")}\n"
      end

      def export_hash
        {
          "id" => @id,
          "name" => @name,
          "task_name" => @task_name,
          "timestamp_start" => @timestamp_start,
          "timestamp_end" => @timestamp_end,
          "entity_id" => @entity.to_s,
          "options" => @options,
          "complete" => @complete,
          "entity_count" => @entity_count,
          "entity_ids" => @entities.map{ |x| x.to_s } #,
          #{}"log" => @log.to_text
        }
      end

      def export_json
        export_hash.to_json
      end
    end
  end
end
