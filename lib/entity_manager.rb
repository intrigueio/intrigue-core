module Intrigue
class EntityManager
  extend Intrigue::System::Helpers
  extend Intrigue::Task::Data

  def self.resolve_type_from_string(type_string)
    raise "INVALID TYPE TO RESOLVE: #{type_string}. DID YOU SEND A STRING? FAILING!" unless type_string.kind_of? String

    # Check full namespace first
    matches = EntityFactory.entity_types.select{|x| x.to_s == type_string }

    # Then check all namespaces underneath
    matches.concat(EntityFactory.entity_types.select{|x|x.to_s.split(":").last.to_s == type_string })

    #note this will be nil if we didn't match
    unless matches.first
      raise "Unable to match to a known entity. Failing on #{type_string}."
    end

  #only return the first (and best) match
  matches.first
  end

  def self.create_bulk_entity(project_id,entity_type_string,entity_name,details)
    
    # create a group
    g = Intrigue::Model::AliasGroup.create(:project_id => project_id)

    # create the entity
    klass = Intrigue::EntityManager.resolve_type_from_string(entity_type_string)
    e = klass.create({
      :name => entity_name.downcase,
      :project_id => project_id,
      :type => entity_type_string,
      :details => details,
      :hidden => false,
      :scoped => true,
      :alias_group_id => g.id
    })
  end

  def self.create_first_entity(project_name,type_string,name,details)

    # Save the original and downcase our name
    details["hidden_original"] = name
    downcased_name = name.downcase

    # Try to find our project and create it if it doesn't exist
    project = Intrigue::Model::Project.find_or_create(:name => project_name)

    # Merge the details if it already exists
    entity = entity_exists?(project,type_string,downcased_name)

    if entity # already exists, but now it's created by us... let's clean it up

      entity.set_details(details.to_h.deep_merge(entity.details.to_h))

        #####
        ### HANDLE USER- or TASK- PROVIDED SCOPING
        #####

          # remove any scope details (though i'm not sure this condition could ever exist on a
          # manually created entity)
          details = details.tap { |h| h.delete("unscoped") }
          details = details.tap { |h| h.delete("scoped") }
          entity.scoped = true
          entity.save_changes

        #####
        ### END ... USER- or TASK- PROVIDED SCOPING
        ###
        ### ENTITIES can SELF-SCOPE, however, for more info on that
        ### see the individual entity file
        #####

    else
      # Create a new entity, validating the attributes
      type = resolve_type_from_string(type_string)
      g = Intrigue::Model::AliasGroup.create(:project_id => project.id)
      entity = Intrigue::Model::Entity.create({
        :name =>  downcased_name,
        :project => project,
        :type => type,
        :details => details,
        :hidden => false, # first entity should NEVER be hidden - it was intentional
        :scoped => true,  # first entity should ALWAYS be in scope - it was intentional
        :alias_group_id => g.id,
        :seed => true
        })
    end

    # necessary because of our single table inheritance?
    new_entity = Intrigue::Model::Entity.find(:id => entity.id)

    ### Ensure we have an entity
    unless new_entity && new_entity.transform! && new_entity.validate_entity
      puts "Error creating entity: #{new_entity}." + "Entity: #{type_string}##{name} #{details}"
      return nil
    end

    # ENRICHMENT MUST BE STARTED MANUALLY!!!!!

  new_entity
  end

  # This method creates a new entity, and kicks off a machine
  def self.create_or_merge_entity(task_result_id,type_string,name,details,primary_entity=nil)

    # Deal with canceled tasks and deleted projects!
    # Do a lookup to make sure we have the latest...
    tr = Intrigue::Model::TaskResult.first(:id => task_result_id)
    return nil unless tr

    if tr.cancelled
      tr.log "Returning, task was cancelled"
      return nil
    end

    # Convenience
    project = tr.project

    # Save the original and downcase our name
    details["hidden_original"] = "#{name}"
    downcased_name = "#{name}".downcase

    # Find the details if it already exists
    entity = entity_exists?(project,type_string,downcased_name)

    # check if this is actually a no-traverse for this proj
    if entity
      traversable = entity.hidden
    else
      # checks to see if we should be hidden or not
      traversable = project.traversable_entity?(name, type_string)
    end

    # Check if there's an existing entity, if so, merge and move forward
    if entity
      tr.log_good "Existing Entity: #{type_string} #{name}. Traversable: #{traversable}"

      entity.set_details(details.to_h.deep_merge(entity.details.to_h))

      # if it already exists, it'll have an alias group ID and we'll
      # want to use that to preserve pre-existing relatiohships
      # also... prevents an enrichment loop
      entity_already_existed = true

    else
      tr.log_good "New Entity: #{type_string} #{name}. Traversable: #{traversable}"

      # Create a new entity, validating the attributes
      type = resolve_type_from_string(type_string)

      # Create a new alias group
      
      entity_details = {
        :name => downcased_name,
        :project_id => project.id,
        :type => type.to_s,
        :details => details,
        :hidden => (traversable ? false : true )
      }

      # handle alias group
      if primary_entity
        entity_details[:alias_group_id] = primary_entity.alias_group_id
      else
        g = Intrigue::Model::AliasGroup.create(:project_id => project.id)
        entity_details[:alias_group_id] = g.id
      end

      #####
      ### HANDLE USER- or TASK- PROVIDED SCOPING
      #####

      # this will help us handle cases of explicit scoping
      # three possible values - nil, "true", "false"
      # will bec converted into a boolean down below
      scope_request = nil

      # if we're told this thing is scoped, let's just mark it scoped
      # note that we delete the detail since we no longer need it
      # TODO... is this used today?
      if (details["scoped"] == true || details["scoped"] == "true")
        tr.log "Entity was specifically requested to be scoped"
        details = details.tap{ |h| h.delete("scoped") }
        scope_request = "true"

      # otherwise if we've specifically decided to unscoped
      # note that we delete the detail since we no longer need it
      elsif (details["unscoped"] == true || details["unscoped"] == "true")
        tr.log "Entity was specifically requested to be unscoped"
        details = details.tap{ |h| h.delete("unscoped") }
        scope_request = "false"

      # if it's set, rely on the task result's auto_scope setting
      # - which is set when the entity is created, based on context
      # that is (or at least should be) specific to that task
      elsif tr.auto_scope
        #tr.log "Task result scoped this entity based on auto_scope"
        scope_request = "true"
      # otherwise default to false, (and let the entity scoping handle it below) 
      else
        #tr.log "No specific scope request from the task result"
        #entity_details[:scoped] = false
      end

      #####
      ### END ... USER- or TASK- PROVIDED SCOPING
      ###
      ### ENTITIES can SELF-SCOPE, however, for more info on that
      ### see the individual entity file
      #####

      begin
        # Create a new entity in that group
        entity = Intrigue::Model::Entity.update_or_create(
          {name: downcased_name, type: type.to_s, project: project}, entity_details)

        unless entity
          tr.log_fatal "Unable to create entity: #{entity_details}"
          return nil
        end

      rescue Encoding::UndefinedConversionError => e
        tr.log_fatal "Unable to create entity:#{entity_details}\n #{e}"
        return nil
      rescue Sequel::DatabaseError => e
        tr.log_fatal "Unable to create entity:#{entity_details}\n #{e}"
        return nil
      end

      # necessary to relookup?
      entity = Intrigue::Model::Entity.find(:id => entity.id)

      ### Ensure we have an entity
      unless entity
        tr.log_error "Unable to create or find entity: #{type}##{downcased_name}, failing!!"
        return nil
      end

      ### final scoping in case the entity has specific scoping instructions
      ##   (now that we have an entity)
      ##
      ##  the default method on the base class simply sets what was available previously
      ##  See the inidivdiual entity files for this logic.
      ##
      if scope_request
        entity.scoped = scope_request.to_bool
      else
        entity.scoped = entity.scoped? #always fall back to our entity-specific logic.
        tr.log "Using entity scoping logic, got #{entity.scoped}"
      end
      entity.save_changes
      tr.log "Final scoping decision for #{entity.name}: #{entity.scoped}"

      ### Run Data transformation (to hide attributes... HACK)
      unless entity.transform!
        tr.log_error "Transformation of entity failed: #{entity}, rolling back entity creation!!"
        entity.delete
        raise "Invalid entity attempted: #{entity.type} #{entity.name}"
      end

      ### Run Validation
      unless entity.validate_entity
        tr.log_error "Validation of entity failed: #{entity}, rolling back entity creation!!"
        entity.delete
        raise "Invalid entity attempted: #{entity.type} #{entity.name}"
      end

      # ENRICHMENT LAUNCH
      if tr.auto_enrich && !entity_already_existed
        # Check if we've alrady run first and return gracefully if so
        if entity.enriched
          tr.log "Skipping enrichment... already completed!"
        else
          # starts a new background task... so anything that needs to happen from
          # this point should happen in that new background task
          entity.enrich(tr)
        end
      else
        tr.log "Skipping enrichment... enrich not enabled!" unless tr.auto_enrich
        tr.log "Skipping enrichment... entity exists!" if entity_already_existed
      end

    end

    
    # Add to our result set for this task
    tr.add_entity entity

    # Attach the alias.. this can be confusing....
    # ----
    # if we already had the entity, it'll already have a group it's associated with.
    # think about the case of a domain lookup where many resolve to a single
    # ip address
    if primary_entity

      $db.transaction do
        
        # Alias to the parent
        pid = primary_entity.alias_group_id
        tr.log "Aliasing #{entity.name} #{entity.alias_group_id} to #{primary_entity.name}'s existing group: #{pid}"
        entity.alias_to(pid)

        # alias all others to the parent
        entity.aliases.each do |a|
          next if a == primary_entity
          next if a.alias_group_id == primary_entity.alias_group_id
          tr.log "Aliasing #{a.name} #{a.alias_group_id} to #{primary_entity.name}'s existing group: #{pid}"
          a.alias_to(pid)
        end

      end

    end

  # return the entity
  entity
  end

  private

  def self._encode_string(string)
    return string unless string.kind_of? String
    string.encode("UTF-8", :undef => :replace, :invalid => :replace, :replace => "?")
  end

  def self._encode_hash(hash)
    return hash unless hash.kind_of? Hash
    hash.each {|k,v| hash[k] = _encode_string(v) if v.kind_of? String }
  hash
  end

end
end
