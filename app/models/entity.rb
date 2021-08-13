# Adding to make it easier to query
module Intrigue
module Core
module Model
class EntitiesTaskResults < Sequel::Model
  self.raise_on_save_failure = false
end
end
end
end

module Intrigue
module Core
module Model

  class Entity < Sequel::Model
    plugin :validation_helpers
    plugin :serialization, :json, :enrichment_tasks_completed, :sensitive_details
    plugin :single_table_inheritance, :type
    plugin :timestamps

    self.raise_on_save_failure = false

    many_to_one  :alias_group
    many_to_many :task_results
    many_to_one  :project
    one_to_many  :issues

    include Intrigue::Core::System::DnsHelpers
    include Intrigue::Core::System::Validations

    def self.inherited(base)
      EntityFactory.register(base)
      super
    end

    def self.scope_by_project(project_name)
      named_project = Intrigue::Core::Model::Project.first(:name => project_name)
      where(Sequel.&(project_id: named_project.id)) if named_project
    end

    def self.scope_by_project_and_type(project_name, entity_type_string)
      resolved_entity_type = Intrigue::EntityManager.resolve_type_from_string(entity_type_string)
      named_project = Intrigue::Core::Model::Project.first(name: project_name)
      where(Sequel.&(project_id: named_project.id, type: resolved_entity_type.to_s)) if named_project
    end

    def uuid
      project_name = self.project.name if self.project
      project_name = "missing_project" unless project_name

      out = "#{project_name}##{self.type}##{self.name}"
      Digest::SHA2.hexdigest(out)
    end

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
      raise "Method must be overidden for #{self.class}!"
    end

    def set_scoped!(bool_val=true, reason=nil)

      # always respect the deny list
      if project.deny_list_entity?(self)
        bool_val = false
        reason = "deny_list_override"
      end

      # but always ALWAYS respect the allow list
      if project.allow_list_entity?(self)
        bool_val = true
        reason = "allow_list_override"
      end

      # Log our scope change
      log_string = "[#{self.project.name}] Entity #{self.type} #{self.name} set scoped to #{bool_val}, reason: #{reason}"
      Intrigue::Core::Model::ScopingLog.log log_string

      self.scoped = bool_val
      self.scoped_at = Time.now.utc.iso8601
      self.scoped_reason = reason
      save_changes

    end

    def seed?
      true if project.seeds.first(:name => self.name)
    false
    end

    def sensitive?
      self.class.metadata[:sensitive] || false
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

    #
    # This method allows us to easily specify a list of type / name pairs for the
    # purpose of verifying scope. The default, is just our own type/name, but consider
    # the example of a URI ... we want to verify the URI itself, the hostname (if
    # not an IP), AND the domain
    #
    #
    def scope_verification_list
      [
        { type_string: self.type_string, name: self.name }
      ]
    end

    # override me... see: lib/entities/domain.rb
    def self.transform_before_save(name, details)
      return name, details
    end

    # override me... see: lib/entities/aws_credential.rb
    def transform!
      true
    end

    # this is just a convenience method
    def enriched?
      self.enriched
    end

    # first checks the current workflow, if nothing provided, use our
    # enrichment_tasks_default method
    def enrichment_tasks
      ['enrich/generic']
    end

    def enrich(task_result)

      ###
      ### Optimization put in place 2020-01-12 ... note that this may not
      ### work for every use case and should be revisited at a later date
      ###
      if self.deny_list #|| self.hidden
        task_result.log "Cowardly refusing to enrich entity on our deny list!: #{task_result.name} #{self.name}"
        return nil
      end

      # grab the task result
      scan_result_id = task_result.scan_result.id if task_result.scan_result
      task_result_depth = task_result.depth

      # if a workflow exists, grab it
      workflow_name = task_result.scan_result ? task_result.scan_result.workflow : nil

      # in order to get the correct enrichment tasks for this entity, we need ot check the current workflow
      # and see if enrichment tasks were specified. If not, we can just use our default.
      our_enrichment_tasks = nil
      wf = Intrigue::WorkflowFactory.create_workflow_by_name(workflow_name)

      if wf && wf.enrichment_defined?
        our_enrichment_tasks = wf.enrichment_for_entity_type(self.type_string)
      else
        # default
        our_enrichment_tasks = enrichment_tasks
      end

      # if this entity has any configured enrichment tasks..
      if our_enrichment_tasks.count > 0

        # Run each one
        our_enrichment_tasks.each do |task_name|

          # if task doesnt exist, mark it enriched using the task of that name
          # ensure we always mark an entity enriched, and then can continue on
          # with the workflow
          unless Intrigue::TaskFactory.include? task_name
            start_task("task_enrichment", self.project, scan_result_id, "enrich/generic", self, task_result_depth, [], [], workflow_name, true)
            next
          end

          start_task("task_enrichment", self.project, scan_result_id, task_name, self, task_result_depth, [], [], workflow_name, true)
        end

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

    def has_detail?(key)
      return nil unless self.details
      details[key] != nil
    end

    def delete_detail(key)
      details = self.details.except(key)
      save_changes
    end

    def get_detail(key)
      return nil unless self.details
      details[key]
    end

    def get_sensitive_detail(key)
      return nil unless self.sensitive_details
      sensitive_details[key]
    end

    def set_detail(key, value)
      begin
        $db.transaction do
          refresh
          self.set(:details => details.merge({key => value}.sanitize_unicode))
          save
        end
      rescue Sequel::NoExistingObject => e
        puts "Error saving details for #{self}: #{e}, deleted?"
      rescue Sequel::DatabaseError => e
        puts "Error saving details for #{self}: #{e}, deleted?"
      end
    end

    def set_sensitive_detail(key, value)
      begin
        $db.transaction do
          refresh
          self.set(:sensitive_details => sensitive_details.merge({key => value}.sanitize_unicode))
          save
        end
      rescue Sequel::NoExistingObject => e
        puts "Error saving details for #{self}: #{e}, deleted?"
      rescue Sequel::DatabaseError => e
        puts "Error saving details for #{self}: #{e}, deleted?"
      end
    end

    def get_and_set_details(new_details={})
      $db.transaction do
        refresh
        self.set(:details => details.merge(new_details.sanitize_unicode))
        save_changes
      end

    end

    def set_details(new_details)
      begin
        $db.transaction do
          refresh
          self.set(:details => new_details.sanitize_unicode)
          save_changes
        end
      rescue Sequel::NoExistingObject => e
        puts "Error saving details for #{self}: #{e}, deleted?"
      rescue Sequel::DatabaseError => e
        puts "Error saving details for #{self}: #{e}, deleted?"
      end
    end

    def set_sensitive_details(new_details)
      begin
        $db.transaction do
          refresh
          self.set(:sensitive_details => new_details.sanitize_unicode)
          save_changes
        end
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

    # Short string with fingeprint details.
    #
    # @return [String]  Semicolon delimted list of fingeprrints
    def short_fingerprint_string(fingerprint)
      fingerprint_array = fingerprint.map do |x|
        if x['vendor'] == x['product']
          fp = "#{x['vendor']} #{x['version']} #{x['update']}".strip # start with just vendor + version
        else # if vendor and product arenot the same, add product
          fp = "#{x['vendor']} #{x['product']} #{x['version']} #{x['update']}".strip
        end
      end
      out = "Fingerprint: #{fingerprint_array.sort.uniq.join("; ")}" if details["fingerprint"]
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
      "#{type_string}: #{name}"
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
            <option> #{URI.encode_www_form_component self.type_string} </option>
          </select>
        </div>
      </div>
      <div class="form-group">
        <label for="attrib_name" class="col-xs-4 control-label">Entity Name</label>
        <div class="col-xs-8">
          <input type="text" class="form-control input-sm" id="attrib_name" name="attrib_name" placeholder="#{self.name}">
        </div>
      </div>}
    end

    def to_v1_api_hash(full=false)
      if full
        export_hash(full)
      else
        {
          :id => id,
          :type => type,
          :name =>  name,
          :deleted => deleted,
          :hidden => hidden,
          :scoped => scoped,
          :alias_group => alias_group_id,
          :detail_string => detail_string
        }
      end
    end

    ###
    ### Export!
    ###
    def export_hash(include_extended=true)

      # check if extended details are allowed to
      # be exported. if not, use short details.
      if include_extended
        export_details = details
      else
        export_details = short_details
      end

      {
        :id => id,
        :type => type,
        :name =>  name,
        :deleted => deleted,
        :hidden => hidden,
        :scoped => scoped,
        :scoped_at => scoped_at,
        :scoped_reason => scoped_reason,
        :alias_group => alias_group_id,
        :detail_string => detail_string,
        :details => export_details,
        :ancestors => ancestors.map{|x| { "type" => x.type, "name" => x.name }},
        :task_results => task_results.map{ |t|
          { :id => t.id,
            :name => t.name,
            #:task_type => t.task_type,
            :base_entity_name => t.base_entity.name,
            :base_entity_type => t.base_entity.type  }
        },
        :enrichment_tasks => enrichment_tasks,
        :generated_at => Time.now.utc.iso8601
      }
    end

    def export_json(extended=false)
      export_hash(extended).to_json
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
end