module Intrigue
  module Model
    class TaskResult

      attr_accessor :id, :name, :timestamp_start, :timestamp_end, :entity, :task_name, :log

      def self.key
        "task_result"
      end

      def key
        Intrigue::Model::TaskResult.key
      end

      def initialize(id,name)

        @id = id
        @name = name
        @lookup_key = "#{key}:#{@id}"
        @timestamp_start = Time.now.getutc.to_s
        @timestamp_end = Time.now.getutc.to_s
        @entity = Entity.new("none",{})
        @task_name = ""
        @entities = []

        @log = TaskResultLog.new(id, name)
      end

      def entities
        puts "entities: #{@entities}"
        @entities
      end

      def self.find(id)
        s = TaskResult.new("nope","nope")
        s.from_json($intrigue_redis.get("#{key}:#{id}"))
        # if we didn't find anything in the db, return nil
        return nil if s.name == "nope"
      s
      end

      def add_entity(entity)
        @entities << entity
        save
      end

      def from_json(json)
        begin
          x = JSON.parse(json)
          @id = x["id"]
          @lookup_key = "#{key}:#{@id}"

          @name = x["name"]
          @task_ids = x["task_ids"]
          @timestamp_start = x["timestamp_start"]
          @timestamp_end = x["timestamp_end"]
          @entity = Entity.find x["entity_id"]
          @task_name = x["task_name"]
          @entities = x["entity_ids"].map {|y| Entity.find y }
          @log = TaskResultLog.find x["log_id"]
          save
        rescue TypeError => e
          return nil
        rescue JSON::ParserError => e
          return nil
        end
      end

      def to_json
        {
          "id" => @id,
          "name" => @name,
          "task_name" => @task_name,
          "timestamp_start" => @timestamp_start,
          "timestamp_end" => @timestamp_end,
          "entity_id" => @entity.id,
          "entity_ids" => @entities.map{ |x| x.id },
          "log_id" => @log.id
        }.to_json
      end

      def to_s
        to_json
      end

      def save
        $intrigue_redis.set @lookup_key, to_json
      end


    end
  end
end
