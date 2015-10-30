module Intrigue
  module Model
    class Entity
      include DataMapper::Resource

      property :id,       Serial
      property :type,     Discriminator
      property :name,     String
      property :details,  Object #Text, :length => 100000

      #has n, :scan_results, through
      belongs_to :task_result, :required => false
      belongs_to :scan_result, :required => false

      #validates_with_method :validate

      before :create, :configure

      def configure
        attribute_set :details, {}
        #save
      end

      def allowed_tasks
        TaskFactory.list ### XXX - this needs to be limited to tasks that accept this type
      end

      def to_s
        "#{type_string}: #{@name}"
      end

      def type_string
        attribute_get(:type).to_s.gsub(/^.*::/, '')
      end

=begin
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

      ###
      ### XXX - needs documentation
      ###
=end
      #def self.inherited(base)
      #  EntityFactory.register(base)
      #end

      def set_attributes(hash)
        attribute_set :details,hash
        save
      end
=begin
      #def to_json
      #  {
      #    :id => id,
      #    :type => metadata[:type],
      #    :attributes => @attributes
      #  }
      #end
=end
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
            <input type="text" class="form-control input-sm" id="attrib_name" name="attrib_name" value="#{_escape_html @name}">
          </div>
        </div>
      }
      end

      def self.descendants
        ObjectSpace.each_object(Class).select { |klass| klass < self }
      end

      private
      def _escape_html(text)
        Rack::Utils.escape_html(text)
        text
      end
    end
  end
end
