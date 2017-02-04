module Intrigue
  module Model

    class AliasMapping < Sequel::Model
      plugin :validation_helpers
      #self.raise_on_save_failure = false

      many_to_one :source, :class => :'Intrigue::Model::Entity', :key => :source_id
      many_to_one :target, :class => :'Intrigue::Model::Entity', :key => :target_id

      def validate
        super
        validates_unique([:source_id, :target_id]) # only allow a single alias
      end

    end

    class Entity < Sequel::Model
      plugin :validation_helpers
      plugin :single_table_inheritance, :type
      plugin :serialization, :json, :details
      self.raise_on_save_failure = false

      #set_allowed_columns :type, :name, :details, :project_id

      many_to_many :task_results
      many_to_one  :project
      many_to_many :aliases, :left_key=>:source_id,:right_key=>:target_id, :join_table=>:alias_mappings, :class=>self

      def validate
        super
        validates_unique([:name, :project_id])
      end

      def deleted?
        return true if deleted
      false
      end
=begin
      def set_detail(name, value)

        # Create a copy of the details so we can update it
        x = details
        x[name] = value

        self.lock!
        self.update(:details => x)
      end
=end
      def self.scope_by_project(project_name)
        named_project_id = Intrigue::Model::Project.first(:name => project_name).id
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
        x = ObjectSpace.each_object(Class).select{ |klass| klass < self }
      end

      ###
      ### Export!
      ###
      def export_hash
        {
          :id => id.to_s,
          :type => type,
          :name =>  name,
          :deleted => deleted,
          :details => details,
          :aliases => self.aliases.map{|x| {
            "id" => x.id,
            "type" => x.type,
            "name" => x.name }},
          :task_results => task_results.map{ |t| {:id => t.id, :name => t.name } }
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
