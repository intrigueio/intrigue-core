module Intrigue
  module Model
    class ScanResult

      attr_accessor :id, :key, :name, :task_ids, :entities

      def self.find(id)
        s = ScanResult.new("aslkd;jflaskdjf","aslkd;jflaskdjf")
        s.from_json($intrigue_redis.get("#{id}"))
        # if we didn't find anything in the db, return nil
        return nil if s.name == "aslkd;jflaskdjf"
      s
      end

      def initialize(id,name)
        @id = id
        @name = name
        @key = "scan_result:#{@id}"
        @task_ids = []
        @entities = []
      end

      def add_task_id(task_id)
        @task_ids << task_id
        save
      end

      def add_entity(entity)
        @entities << entity
        save
      end

      def from_json(json)
        begin
          x = JSON.parse(json)
          @id = x["id"]
          @name = x["name"]
          @task_ids = x["task_ids"]
          @key = "scan_result:#{@id}"
          @entities = x["entities"]
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
          "key" => @key,
          "task_ids" => @task_ids,
          "entities" => @entities
        }.to_json
      end

      def to_s
        to_json
      end

      def save
        $intrigue_redis.set @key, to_json
      end


    end
  end
end
