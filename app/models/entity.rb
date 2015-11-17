module Intrigue
  module Model
    class Entity
      include DataMapper::Resource

      property :id,       Serial
      property :type,     Discriminator
      property :name,     String
      property :details,  Object, :default => {} #Text, :length => 100000

      belongs_to :task_result, :required => false
      belongs_to :scan_result, :required => false

      def allowed_tasks
        ### XXX - this needs to be limited to tasks that accept this type
        TaskFactory.list
      end

      def to_s
        "#{type_string}: #{@name}"
      end

      def type_string
        attribute_get(:type).to_s.gsub(/^.*::/, '')
      end

      # Method returns true if entity has the same attributes
      # false otherwise
      def match?(entity)
        if (entity.name == @name &&
            entity.type == @type &&
            entity.details == @details)
            puts "DEBUG #{entity} matched #{self}"
            return true
        end
      false
      end

      def form
        %{
        <!-- auto generated via entity model -->
        <div class="form-group">
          <label for="entity_type" class="col-xs-4 control-label">Entity Type</label>
          <div class="col-xs-6">
            <input type="text" class="form-control input-sm" id="entity_type" name="entity_type" value="#{type_string}">
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

      ###
      ### Export!
      ###

      def export_hash
        {
          :type => @type,
          :name => @name,
          :details => @details
        }
      end

      def export_json
        export_hash.to_json
      end

      private
      def _escape_html(text)
        Rack::Utils.escape_html(text)
        text
      end
    end
  end
end
