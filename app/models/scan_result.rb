module Intrigue
  module Model
    class ScanResult

      attr_accessor :id, :key, :name

      def self.find(id)
        x = $intrigue_redis.get("#{id}")
        s = ScanResult.new("template","template")
        s.from_json x
      s
      end

      def initialize(id,name)
        @id = id
        @name = name
        @key = "scan_result:#{@id}"
        @task_results = []
      end

      def from_json(json)
        x = JSON.parse(json)
        @id = x["id"]
        @name = x["name"]
        @task_results = x["task_results"]
        @key = "scan_result:#{@id}"
        save
      end

      #def add_task_result(task_result)
      #  @task_results << task_result
      #  _persist
      #end

      def to_json
        {
          "id" => @id,
          "name" => @name,
          "key" => @key,
          "value" => @task_results
        }.to_json
      end

      def save
        $intrigue_redis.set @key, to_json
      end


    end
  end
end
