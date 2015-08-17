module Intrigue
  module Model
    class Entity

      attr_accessor :id, :type, :attributes

      def self.key
        "entity"
      end

      def key
        "#{Intrigue::Model::Entity.key}"
      end

      def initialize(type,attributes)
        @id = SecureRandom.uuid
        @type = type
        @attributes = attributes
      end

      def self.find(id)
        lookup_key = "#{key}:#{id}"
        result = $intrigue_redis.get(lookup_key)
        raise "Unable to find #{lookup_key}" unless result

        s = Entity.new("nope","nope")
        s.from_json(result)
        s.save

        # if we didn't find anything in the db, return nil
        return nil if s.id == "nope"
      s
      end

      def from_json(json)
        begin
          x = JSON.parse(json)
          @id = x["id"]
          @type = x["type"]
          @attributes = x["attributes"]
        rescue JSON::ParserError => e
          puts "OH NOES! ITEM DID NOT EXIST, OR OTHER ERROR PARSING #{json}"
        end
      end

      def to_hash
        {
          "id" => @id,
          "type" => @type,
          "attributes" => @attributes
        }
      end

      def to_json
        to_hash.to_json
      end

      def to_s
        self.inspect.to_s
      end

      def save
        lookup_key = "#{key}:#{@id}"
        $intrigue_redis.set lookup_key, to_json
      end

    end
  end
end
