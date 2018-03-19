module Intrigue
  module Model

    class AliasGroup < Sequel::Model
      one_to_many :entities
      many_to_one :project

      def self.scope_by_project(project_name)
        named_project = Intrigue::Model::Project.first(:name => project_name)
        where(Sequel.&(:project_id => named_project.id))
      end

    end

    class Entity < Sequel::Model
      plugin :validation_helpers
      plugin :single_table_inheritance, :type
      plugin :serialization, :json, :details, :details_raw #, :name

      self.raise_on_save_failure = false

      many_to_one  :alias_group
      many_to_many :task_results
      many_to_one  :project

      include Intrigue::Model::Capabilities::CalculateProvider

      def ancestors
        ancestors = []
        task_results.each do |tr|
          ancestors << tr.scan_result.base_entity if tr.scan_result
        end

      ancestors
      end

      def validate
        super
        validates_unique([:project_id, :type, :name])
      end

      def safe_details
        details.select { |k,v| !k.to_s.match(/^hidden_.*$/) }
      end

      def transform!
        true
      end

      def enrichment_scheduled?(task_name)
        true if Intrigue::Model::TaskResult.first(:task_name => task_name, :base_entity_id => self.id, :cancelled => false)
      end

      def alias(entity)

        # They'd share the same group...
        self.alias_group_id = entity.alias_group_id
        save

      end

      def self.scope_by_project(project_name)
        named_project = Intrigue::Model::Project.first(:name => project_name)
        where(Sequel.&(:project_id => named_project.id, :deleted => false))
      end

      def self.scope_by_project_and_type(project_name, entity_type)
        resolved_entity_type = Intrigue::EntityManager.resolve_type(entity_type)
        named_project = Intrigue::Model::Project.first(:name => project_name)
        where(Sequel.&(:project_id => named_project.id, :type => resolved_entity_type.to_s, :deleted => false))
      end

      def self.scope_by_project_and_type_and_detail_value(project_name, entity_type, detail_name, detail_value)
        json_details = Sequel.pg_jsonb_op(:details)
        candidate_entities = scope_by_project_and_type(project_name,entity_type)
        candidate_entities.where(json_details.get_text(detail_name) => detail_value)
      end

      # Override this if you are creating a secondary entity
      # (meaning... it'll be tracked through another entity)
      def primary
        true
      end

      # grab all entities in this group
      def aliases
        return [] unless alias_group

        alias_group.entities.sort_by{|x| x.name }
      end

      # easy way to refer to all names (overridden in some entities)
      def unique_name
        [name].concat(aliases.map{|x| x.name }).sort.uniq
      end

      # easy way to refer to all names (overridden in some entities)
      def unique_alias_names
        aliases.select{|x| x.name unless x.hidden }.sort_by{|x| x.name }.uniq
      end

      def has_detail(key)
        details[key] != nil
      end

      def get_detail(key)
        details[key]
      end

      def set_detail(key, value)
        self.lock!
        temp_details = details.merge({key => value}.sanitize_unicode)
        self.set(:details => temp_details)
        self.set(:details_raw => temp_details)

        save
      end

      def set_details(hash)
        self.lock!
        self.set(:details => hash.sanitize_unicode)
        self.set(:details_raw => hash.sanitize_unicode)
        save
      end

      # Short string with select details. overriden by specific types.
      #
      # @return [String] light details about this entity
      def detail_string
        ""
      end

      # Marks the entity and aliases as deleted (but doesnt actually delete)
      #
      # @return [TrueClass] true if successful
      def soft_delete!
        # clean up aliases at the same time
        alias_group.each {|x| x.soft_delete!}
        deleted = true
        save
      end

      # Check whether the entity is deleted
      #
      # @return [TrueClass] true if it deleted
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
        "#{type_string}: #{name}#{' <H>' if hidden}"
      end

      def inspect
        "#{type_string}: #{name}#{' <H>' if hidden}"
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
          <div class="col-xs-8">
            <select class="form-control input-sm" id="entity_type" name="entity_type">
              <option> #{self.type_string} </option>
            </select>
          </div>
        </div>
        <div class="form-group">
          <label for="attrib_name" class="col-xs-4 control-label">Entity Name</label>
          <div class="col-xs-8">
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
          :id => id,
          :type => type,
          :name =>  name,
          :deleted => deleted,
          :hidden => hidden,
          :details => safe_details,
          #:task_results => task_results.map{ |t| {:id => t.id, :name => t.name } },
          :aliases => aliases.map{ |x| {:id => x.id, :name => x.name } }
        }
      end

      def export_json
        export_hash.to_json
      end

      def export_csv
        "#{type}, #{name}, #{detail_string.gsub(",",";") if detail_string}"
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
