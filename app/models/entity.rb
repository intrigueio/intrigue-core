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

      def allowed_tasks
        TaskFactory.list ### XXX - this needs to be limited to tasks that accept this type
      end

      def self.find(id)
        lookup_key = "#{key}:#{id}"
        result = $intrigue_redis.get(lookup_key)
        return nil unless result

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

      def to_s
        export_hash
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

      ###
      ### Export!
      ###

      def export_hash
        to_hash
      end

      def export_json
        to_hash.to_json
      end

      def save
        lookup_key = "#{key}:#{@id}"
        $intrigue_redis.set lookup_key, to_json
      end

      ###
      ### XXX - needs documentation
      ###

      def self.inherited(base)
        EntityFactory.register(base)
      end

      def set_attribute(key, value)
        @attributes[key.to_s] = value
        save
        return false unless validate(attributes)
      true
      end

      def set_attributes(attributes)
        return false unless validate(attributes)
        @attributes = attributes
        save
      end

      #def to_json
      #  {
      #    :id => id,
      #    :type => metadata[:type],
      #    :attributes => @attributes
      #  }
      #end

      def form
        %{
        <div class="form-group">
          <label for="entity_type" class="col-xs-4 control-label">Type</label>
          <div class="col-xs-6">
            <input type="text" class="form-control input-sm" id="entity_type" name="entity_type" value="#{@type}">
          </div>
        </div>
        <div class="form-group">
          <label for="attrib_name" class="col-xs-4 control-label">Name</label>
          <div class="col-xs-6">
            <input type="text" class="form-control input-sm" id="attrib_name" name="attrib_name" value="#{_escape_html @attributes["name"]}">
          </div>
        </div>
      }
      end

      # override this method
      def metadata
        raise "Metadata method should be overridden"
      end

      # override this method
      def validate(attributes)
        raise "Validate method missing for #{self.type}"
      end

      private
      def _escape_html(text)
        Rack::Utils.escape_html(text)
        text
      end

    end
  end
end
