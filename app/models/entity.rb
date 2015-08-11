module Intrigue
  module Model
    class Entity

      attr_accessor :id, :key, :type, :attributes

      def self.key
        "entity"
      end

      def key
        Intrigue::Model::Entity.key
      end

      def initialize(type,attributes)
        @id = SecureRandom.uuid
        @lookup_key = "#{key}:#{@id}"
        @type = type
        @attributes = attributes
      end

      def self.find(id)
        s = Entity.new("nope","nope")
        s.from_json($intrigue_redis.get("#{key}:#{id}"))

        # if we didn't find anything in the db, return nil
        return nil if s.id == "nope"
      s
      end

      def from_json(json)
        begin
          x = JSON.parse(json)
          if x["id"]
            @id = x["id"]
          else
            @id = SecureRandom.uuid
          end

          @lookup_key = "#{key}:#{@id}"
          @type = x["type"]
          @attributes = x["attributes"]
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
          "type" => @type,
          "attributes" => @attributes
        }.to_json
      end

      def save
        $intrigue_redis.set @lookup_key, to_json
      end

    end
  end
end
