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
      plugin :serialization, :json, :details #, :name
      self.raise_on_save_failure = false

      many_to_many :aliases, :left_key=>:source_id,:right_key=>:target_id, :join_table=>:alias_mappings, :class=>self
      many_to_many :task_results
      many_to_one  :project

      def validate
        super
        validates_unique([:project_id, :type, :name])
      end

      def self.scope_by_project(project_name)
        named_project_id = Intrigue::Model::Project.first(:name => project_name).id
        where(:project_id => named_project_id)
      end

      def self.scope_by_project_and_type(project_name, entity_type)
        resolved_entity_type = Intrigue::EntityManager.resolve_type(entity_type)
        named_project_id = Intrigue::Model::Project.first(:name => project_name).id
        where(Sequel.&(:project_id => named_project_id, :type => resolved_entity_type.to_s))
      end

      # Override this if you are creating a secondary entity
      # (meaning... it'll be tracked through another entity)
      def primary
        true
      end

      # easy way to refer to all names (overridden in some entities)
      def unique_name
        [name].concat(aliases.map{|x| x.name }).sort.uniq
      end

      # short string with select details. override this.
      def detail_string
        ""
      end

      def soft_delete!
        # clean up aliases at the same time
        aliases.each {|x| x.soft_delete!}

        deleted = true
        save
      end

      def deleted?
        return true if deleted
      false
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

      def get_aliases(filter_type_string)
        aliases.map {|x| x if x.type_string == filter_type_string }
      end

      def get_detail(key)
        details[key]
      end

      def set_detail(key,value)
        details[key] = value
        save
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
          :aliases => aliases.map{ |x| {:id => x.id, :name => x.name } },
          :task_results => task_results.map{ |t| {:id => t.id, :name => t.name } }
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


      ### VALIDATIONS!

      # https://tools.ietf.org/html/rfc1123
      def _v4_regex
        /(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/
      end

      def _v6_regex
        /^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$/
      end

      def _dns_regex
        /^(\w|-|\.).*\.(\w|-|\.).*$/
      end

    end
  end
end
