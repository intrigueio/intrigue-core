module Intrigue
  module Model
    class Entity
      include DataMapper::Resource

      validates_uniqueness_of :name, :scope => :project

      property :type,     Discriminator
      property :id,       Serial, :key => true
      property :name,     String, :length => 200, :index => true
      property :details,  Object, :default => {}

      # TODO - we must add a cooresponding mapping and a destroy contstraint here
      belongs_to :project, :default => lambda { |r, p| Intrigue::Model::Project.first }
      has n, :task_results, :through => Resource, :constraint => :destroy

      def self.scope_by_project(name)
        all(:project => Intrigue::Model::Project.first(:name => name))
      end

      def children
        results = []
        task_results.each { |t| t.entities.each { |e| results << e } }
      results
      end

      def created_by?(task_name)
        task_results.each {|x| return true if x.task_name == task_name }
      false
      end

      def allowed_tasks
        ### XXX - this needs to be limited to tasks that accept this type
        TaskFactory.allowed_tasks_for_entity_type(type_string)
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
        if ( entity.name == @name && entity.type == @type )
            return true
        end
      false
      end

      def form
         %{<div class="form-group">
          <label for="entity_type" class="col-xs-4 control-label">Entity Type</label>
          <div class="col-xs-6">
            <select class="form-control input-sm" id="entity_type" name="entity_type">
              <option> #{self.type_string} </option>
            </select>
          </div>
        </div>
        <div class="form-group">
          <label for="attrib_name" class="col-xs-4 control-label">Entity Name</label>
          <div class="col-xs-6">
            <input type="text" class="form-control input-sm" id="attrib_name" name="attrib_name" value="#{self.name}">
          </div>
        </div>}
      end

      def self.descendants
        ObjectSpace.each_object(Class).select { |klass| klass < self }
      end

      ###
      ### Export!
      ###
      def export_hash
        {
          :id => @id.to_s,
          :type => @type,
          :name =>  @name,
          :details => @details
        }
      end

      def export_json
        export_hash.to_json
      end

      # export id, type, name, and details on a single line, removing spaces and commas
      def export_csv
        export_string = "#{@id},#{type_string},#{@name.gsub(/[\,,\s]/,"")},"
        @details.each{|k,v| export_string << "#{k}=#{v};".gsub(/[\,,\s]/,"") }
      export_string
      end

      def export_tsv
        export_string = "#{@id}\t#{type_string}\t#{@name}\t"
        @details.each{|k,v| export_string << "#{k}##{v};" }
      export_string
      end

      private
      def _escape_html(text)
        Rack::Utils.escape_html(text)
        text
      end
    end
  end
end
