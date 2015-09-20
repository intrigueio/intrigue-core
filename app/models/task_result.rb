module Intrigue
  module Model
    class TaskResult

      attr_accessor :id, :name, :timestamp_start, :timestamp_end
      attr_accessor :options, :entity, :task_name, :entities, :log
      attr_accessor :complete, :entity_count

      def self.key
        "task_result"
      end

      def key
        "#{Intrigue::Model::TaskResult.key}"
      end

      def initialize(id,name)
        @id = id
        @name = name
        @lookup_key = "#{key}:#{@id}"
        @timestamp_start = DateTime.now
        @timestamp_end = DateTime.now
        @entity = nil
        @entity_count = 0
        @task_name = nil
        @options = []
        @entities = []
        @complete = false
        @log = TaskResultLog.new(id, name); @log.save # save must be called to persist objects
      end

      def entities
        @entities
      end

      def entity_id
        if @entity
          @entity.id
        else
          nil
        end
      end


      def self.find(id)
        lookup_key = "#{key}:#{id}"
        result = $intrigue_redis.get(lookup_key)
        return nil unless result

        s = TaskResult.new("nope","nope")
        s.from_json(result)
        s.save

        # if we didn't find anything in the db, return nil
        return nil if s.name == "nope"
      s
      end

      def add_entity(entity)
        # Check to see if we already have first
        return false if has_entity? entity

        #@log.log "Adding entity #{entity.inspect}"
        @entity_count+=1
        @entities << entity
        save
      true
      end

      # Matches based on type and the attribute "name"
      def has_entity? entity
        #@log.log "Checking for entity #{entity.inspect}"
        x = @entities.select{|e| e.export_json == entity.export_json }
      return !x.empty?
      end

      def from_json(json)
        begin
          x = JSON.parse(json)
          @id = x["id"]
          @name = x["name"]
          @task_ids = x["task_ids"]
          @timestamp_start = x["timestamp_start"]
          @timestamp_end = x["timestamp_end"]
          @entity = Entity.find x["entity_id"]
          @task_name = x["task_name"]
          @entity_count = x["entity_count"]
          @options = x["options"]
          @entities = x["entity_ids"].map { |y| Entity.find y }
          @complete = x["complete"]
          @log = TaskResultLog.find x["id"]
        rescue JSON::ParserError => e
          return nil
        end
      end

      def to_s
        to_json
      end

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
          "entity_ids" => @entities.map{ |x| x.id if x}
        }
      end

      def to_json
        to_hash.to_json
      end

      ###
      ### Export!
      ###

      def export_csv
        "#{@task_name},#{@entity.attributes["name"]},#{@entities.map{|x| x.type + "#" + x.attributes["name"] }.join(";")}\n"
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
          "entity_ids" => @entities.map{ |x| x.to_s }
        }
      end

      def export_json
        export_hash.to_json
      end


      def save
        lookup_key = "#{key}:#{@id}"
        $intrigue_redis.set lookup_key, to_json
      end

    end
  end
end
