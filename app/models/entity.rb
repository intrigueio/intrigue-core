module Intrigue
  module Model

    class AliasMapping < Sequel::Model
      plugin :validation_helpers

      #many_to_one :source, :class => Intrigue::Model::Entity
      #many_to_one :target, :class => Intrigue::Model::Entity

      many_to_one :source, :class => :'Intrigue::Model::Entity', :key => :source_id
      many_to_one :target, :class => :'Intrigue::Model::Entity', :key => :target_id

      def validate
        super
      end

    end

    class Entity < Sequel::Model
      plugin :validation_helpers
      plugin :single_table_inheritance, :type
      plugin :serialization, :json, :details

      #set_allowed_columns :type, :name, :details, :project_id

      many_to_many :task_results
      one_to_many :aliases, :class => :'Intrigue::Model::AliasMapping', :key => :source_id
      many_to_one :project
      #one_to_many :task_result, :key => :base_entity_id

      def validate
        super
        #validates_uniqueness_of :name, :scope => :project
        #validates_length_of :name, :min => 2
      end

      def self.scope_by_project(name)
        named_project_id = Intrigue::Model::Project.first(:name => name).id
        where(:project_id => named_project_id)
      end

      def self.scope_by_project_and_type(project, type)
        named_project_id = Intrigue::Model::Project.first(:name => project).id
        where(Sequel.&(:project_id => named_project_id, :type => type.to_s))
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
        "#{type_string}: #{name}"
      end

      def type_string
        type.to_s.gsub(/^.*::/, '')
      end

      # Method returns true if entity has the same attributes
      # false otherwise
      def match?(entity)
        if ( entity.name == name && entity.type == type )
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
          :id => id.to_s,
          :type => type,
          :name =>  name,
          :secondary => secondary,
          :details => details,
          :aliases => self.aliases.map{|x| {
            "id" => x.id,
            "type" => x.type,
            "name" => x.name }},
          :task_results => task_results
        }
      end

      def export_json
        export_hash.to_json
      end

      # export id, type, name, and details on a single line, removing spaces and commas
      def export_csv
        export_string = "#{id},#{type_string},#{name.gsub(/[\,,\s]/,"")},"
        details.each{|k,v| export_string << "#{k}=#{v};".gsub(/[\,,\s]/,"") }
      export_string
      end

      def export_tsv
        export_string = "#{id}\t#{type_string}\t#{name}\t"
        details.each{|k,v| export_string << "#{k}##{v};" }
      export_string
      end

      private
      def _escape_html(text)
        Rack::Utils.escape_html(text)
        text
      end

      # have an easy way to sort and hash all the aliases (which should include
      # all names)
      def _unique_name
        string = aliases.split(",").sort_by{|x| x.downcase}.join(", ")
        Digest::SHA1.hexdigest string
      end

    end
  end
end
