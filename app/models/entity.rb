# Adding to make it easier to query
module Intrigue
module Model
class EntitiesTaskResults < Sequel::Model
end
end
end

module Intrigue
  module Model

    class Entity < Sequel::Model
      plugin :validation_helpers
      plugin :single_table_inheritance, :type
      plugin :timestamps

      self.raise_on_save_failure = false

      many_to_one  :alias_group
      many_to_many :task_results
      many_to_one  :project
      one_to_many  :issues

      include Intrigue::Task::Helper
      include Intrigue::System::Validations
      
      def self.inherited(base)
        EntityFactory.register(base)
        super
      end

      def self.scope_by_project(project_name)
        named_project = Intrigue::Model::Project.first(:name => project_name)
        where(Sequel.&(project_id: named_project.id)) if named_project
      end

      def self.scope_by_project_and_type(project_name, entity_type_string)
        resolved_entity_type = Intrigue::EntityManager.resolve_type_from_string(entity_type_string)
        named_project = Intrigue::Model::Project.first(name: project_name)
        where(Sequel.&(project_id: named_project.id, type: resolved_entity_type.to_s)) if named_project
      end

      #def self.scope_by_project_and_type_and_detail_value(project_name, entity_type, detail_name, detail_value)
      #  json_details = Sequel.pg_jsonb_op(:details)
      #  candidate_entities = scope_by_project_and_type(project_name,entity_type)
      #  our_value = json_details.get_text(detail_name)
      #  candidate_entities.where(our_value => detail_value)
      #end
      
      def ancestors
        ancestors = []
        task_results.each do |tr|
          ancestors << tr.scan_result.base_entity if tr.scan_result
        end
      ancestors.uniq
      end

      def match_entity_string?(entity_type, entity_name)
        
        # just in case (handles a current error)
        return false unless entity_type && entity_name && self.name

        #puts "Attempting to match #{entity_type} #{entity_name} to #{self.type_string} #{self.name}"
        return true if (self.type_string.downcase == entity_type.downcase && self.name.downcase == entity_name.downcase)
      false
      end 

      # default method that scopes / unscoped entities (can be overridden)
      # TODO ... maybe we move the logic of details that exists in entity_manager here?
      def scoped?
        raise "Method must be oveeridden for #{self.class}!"
      end

      def validate
        super
        validates_unique([:project_id, :type, :name])
      end

      def validate_entity
        raise "Should be called on subclass..."
      end

      def short_details # ideally this is just excluding extended_ stuff
        details.reject{ |k,v|
          k.to_s.match(/^hidden_.*$/) || k.to_s.match(/^extended_.*$/) || k.to_s.match(/^encoded_.*$/)  }
      end

      def extended_details # ideally this is just including extended_ stuff
        details.select{ |k,v|
          k.to_s.match(/^hidden_.*$/) || k.to_s.match(/^extended_.*$/)|| k.to_s.match(/^encoded_.*$/) }
      end

      def has_extended_details?
        extended_details.count > 1 # hidden_name will always exist...
      end

      # override me... see: lib/entities/aws_credential.rb
      def transform!
        true
      end

      def enriched?
        self.enriched
      end

      # overridden in the individual entities
      def enrichment_tasks
        []
      end

      def enrich(task_result)

        # grab the task result
        scan_result_id = task_result.scan_result.id if task_result.scan_result 
        task_result_depth = task_result.depth 

        # if a machine exists, grab it
        machine_name = task_result.scan_result ? task_result.scan_result.machine : nil

        # if this entity has any configured enrichment tasks..
        if enrichment_tasks.count > 0

          # Run each one
          enrichment_tasks.each do |task_name|

            # if task doesnt exist, mark it enriched using the task of that name
            # ensure we always mark an entity enriched, and then can continue on
            # with the machine
            unless Intrigue::TaskFactory.include? task_name
              start_task("task_enrichment", self.project, scan_result_id, "enrich/generic", self, task_result_depth, [], [], machine_name, true, true)
              next
            end

            start_task("task_enrichment", self.project, scan_result_id, task_name, self, task_result_depth, [], [], machine_name, true, true)
          end

        else # always enrich, even if something is not configured
          start_task("task_enrichment", self.project, scan_result_id, "enrich/generic", self, task_result_depth, [], [], machine_name, true, true)
        end

      end

      def alias_to(new_id)
        # They'd share the same group...
        self.alias_group_id = new_id
        save_changes
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
        return nil unless self.details
        details[key] != nil
      end

      def get_detail(key)
        return nil unless self.details
        details[key]
      end

      def set_detail(key, value)
        begin
          self.set(:details => details.merge({key => value}.sanitize_unicode))
          save
        rescue Sequel::NoExistingObject => e
          puts "Error saving details for #{self}: #{e}, deleted?"
        rescue Sequel::DatabaseError => e
          puts "Error saving details for #{self}: #{e}, deleted?"
        end
      end

      def get_details
        details
      end

      def set_details(hash)
        begin
          self.set(:details => hash.sanitize_unicode)
          save
        rescue Sequel::NoExistingObject => e
          puts "Error saving details for #{self}: #{e}, deleted?"
        rescue Sequel::DatabaseError => e
          puts "Error saving details for #{self}: #{e}, deleted?"
        end
      end

      # Short string with select details. overriden by specific types.
      #
      # @return [String] light details about this entity
      def detail_string
        nil
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
        TaskFactory.allowed_tasks_for_entity_type(type_string)
      end

      def to_s
        "#{type_string}: #{name}#{' <Hidden>' if hidden} #{' <Unscoped>' unless scoped}"
      end

      def type_string
        self.class.to_s.split(":").last
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
          :scoped => scoped,
          :alias_group => alias_group_id,
          :detail_string => detail_string,
          :details => details,
          :ancestors => ancestors.map{|x| { "type" => x.type, "name" => x.name }},
          :task_results => task_results.map{ |t|
            { :id => t.id,
              :name => t.name,
              #:task_type => t.task_type,
              :base_entity_name => t.base_entity.name,
              :base_entity_type => t.base_entity.type  }
          }
        }
      end

      def export_json
        export_hash.merge("generated_at" => "#{Time.now.utc}").to_json
      end

      def export_csv
        "#{type}, #{name}, #{detail_string.gsub(",",";") if detail_string}, #{hidden}, #{deleted}, #{alias_group_id}"
      end

      def _escape_html(text)
        Rack::Utils.escape_html(text)
        text
      end

    end
  end
end
