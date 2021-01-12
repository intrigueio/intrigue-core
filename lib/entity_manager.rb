module Intrigue
class EntityManager
  
  extend Intrigue::Core::System::Helpers
  extend Intrigue::Task::Data

  ###
  ### Resolves a type from a type_string (which is the last part of the type's 
  ### name as a string.
  ###
  def self.resolve_type_from_string(type_string)
    raise "#{type_string} must be a string. FAILING!" unless type_string.kind_of? String

    # Check full namespace first
    matches = EntityFactory.entity_types.select{|x| "#{x}" == type_string }

    # Then check all namespaces underneath
    matches.concat(EntityFactory.entity_types.select{|x| "#{x}".split(":").last == type_string })

    #note this will be nil if we didn't match
    unless matches.first
      raise "Unable to match to a known entity. Failing on #{type_string}."
    end

  # only return the first (and best) match
  matches.first
  end

  def self.create_bulk_entity(project_id,entity_type_string,entity_name,details)
    
    # create a group
    g = Intrigue::Core::Model::AliasGroup.create(:project_id => project_id)

    # create the entity
    klass = Intrigue::EntityManager.resolve_type_from_string(entity_type_string)
    e = klass.create({
      :name => entity_name.downcase,
      :project_id => project_id,
      :type => entity_type_string,
      :details => details,
      :hidden => false,
      :scoped => true,
      :allow_list => true,
      :deny_list => false,
      :alias_group_id => g.id
    })
  end

  def self.create_first_entity(project_name,type_string,name,details)

    # Save the original and downcase our name
    details["hidden_original"] = name
    downcased_name = name.downcase

    # Try to find our project and create it if it doesn't exist
    project = Intrigue::Core::Model::Project.find_or_create(:name => project_name)

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
      entity.set_scoped!(true, "first_entity")
      
      # also we can now mark it as a seed!
      entity.seed = true

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
      g = Intrigue::Core::Model::AliasGroup.create(:project_id => project.id)
      entity = Intrigue::Core::Model::Entity.create({
        :name =>  downcased_name,
        :project => project,
        :type => type,
        :details => details,
        :hidden => false, # first entity should NEVER be hidden - it was intentional
        :scoped => true,  # first entity should ALWAYS be in scope - it was intentional
        :allow_list => true,
        :deny_list => false,
        :alias_group_id => g.id,
        :seed => true
        })
    end

    # necessary because of our single table inheritance?
    new_entity = Intrigue::Core::Model::Entity.find(:id => entity.id)

    ### Ensure we have an entity
    unless new_entity && new_entity.transform! && new_entity.validate_entity
      puts "Error creating entity: #{new_entity}." + "Entity: #{type_string}##{name} #{details}"
      return nil
    end

    # ENRICHMENT MUST BE STARTED MANUALLY!!!!!

  new_entity
  end

  # This method creates a new entity, and kicks off a workflow
  def self.create_or_merge_entity(task_result_id,type_string,name,details,primary_entity=nil)

    # Deal with canceled tasks and deleted projects!
    # Do a lookup to make sure we have the latest...
    tr = Intrigue::Core::Model::TaskResult.first(:id => task_result_id)
    return nil unless tr

    if tr.cancelled
      tr.log "Returning, task was cancelled"
      return nil
    end

    # Convenience
    project = tr.project

    # Save the original and downcase our name
    details["hidden_original"] = "#{name}".strip
    downcased_name = "#{name}".strip.downcase

    # Find the details if it already exists
    entity = entity_exists?(project,type_string,downcased_name)

    # Check if there's an existing entity, if so, merge and move forward
    entity_already_existed = false
    if entity

      entity.set_details(details.to_h.deep_merge(entity.details.to_h))

      # if it already exists, it'll have an alias group ID and we'll
      # want to use that to preserve pre-existing relatiohships
      # also... prevents an enrichment loop
      entity_already_existed = true
    else

      # Create a new entity, validating the attributes
      type = resolve_type_from_string(type_string)

      allowed_list = project.allow_list_entity?(type_string, downcased_name)
      denied_list = project.deny_list_entity?(type_string, downcased_name)

      entity_details = {
        :name => downcased_name,
        :project_id => project.id,
        :type => type.to_s,
        :details => details,
        :allow_list => allowed_list,
        :deny_list => denied_list,
        :traversable => project.traversable_entity?(type_string, downcased_name) ? true : false, 
        :hidden => (project.traversable_entity?(type_string, downcased_name) ? false : true )
      }

      # handle alias group
      if primary_entity
        entity_details[:alias_group_id] = primary_entity.alias_group_id
      else
        g = Intrigue::Core::Model::AliasGroup.create(:project_id => project.id)
        entity_details[:alias_group_id] = g.id
      end

      begin
        # Create a new entity in that group
        entity = Intrigue::Core::Model::Entity.update_or_create(
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
      entity = Intrigue::Core::Model::Entity.find(:id => entity.id)

      ### Ensure we have an entity
      unless entity
        tr.log_error "Unable to create or find entity: #{type}##{downcased_name}, failing!!"
        raise InvalidEntityError.new("Invalid entity, unable to find: #{entity}")
      end

      ### Run transformation (to hide attributes... HACK)
      unless entity.transform!
        tr.log_error "Transformation of entity failed: #{entity}, rolling back entity creation!!"
        entity.delete
        raise InvalidEntityError.new("Invalid entity, unable to transform: #{entity}")
      end

      ### Run Validation
      unless entity.validate_entity
        tr.log_error "Validation of entity failed: #{entity}, rolling back entity creation!!"
        entity.delete
        raise InvalidEntityError.new("Invalid entity, unable to validate: #{entity}")
      end

    end
    
    ###
    ### SCOPING MUST ALWAYS RE-RUN
    ###

    #####
    ### HANDLE TASK DRIVEN ENTITY SCOPING - which can be applied to existing entities
    ### ... first, deal with USER- or TASK-PROVIDED SCOPING
    #####

    # this will help us handle cases of explicit scoping
    # three possible values - nil, "true", "false"
    # will bec converted into a boolean down below
    scope_request = nil

    # if it's set, rely on the task result's auto_scope setting
    # - which is set when the entity is created, based on context
    # that is (or at least should be) specific to that task... this 
    # is usually specific to enrichment tasks
    if tr.auto_scope
      #tr.log "Task result scoped this entity based on auto_scope."
      scope_request = "true"
    else # otherwise default to false, (and let the entity scoping handle it below) 
      tr.log "No specific scope request from the task result or the entity creation"
      #entity_details[:scoped] = false
    end

    # If we're told this thing is scoped, let's just mark it scoped
    # note that we delete the detail since we no longer need it
    # TODO... is this used today?
    if (details["scoped"] == true || details["scoped"] == "true")
      tr.log "Entity was specifically requested to be scoped"
      details = details.tap{ |h| h.delete("scoped") }
      scope_request = "true"

    # otherwise if we've specifically decided to unscope
    # note that we delete the detail since we no longer need it
    elsif (details["unscoped"] == true || details["unscoped"] == "true")

      unless entity.seed? 
        tr.log "Entity was specifically requested to be unscoped"
        details = details.tap{ |h| h.delete("unscoped") }
        scope_request = "false"
      else
        tr.log "Entity was specifically requested to be unscoped, but it's a seed, so we refused!"
      end

    end

    #####
    ###
    ### END ... USER- or TASK- PROVIDED SCOPING
    ###
    ### ENTITIES can SELF-SCOPE, however, for more info on that
    ### see the individual entity file's scoped? method
    ###
    ### this is the default case when entities are created by 
    ### normal tasks
    ###
    #####

    # ENRICHMENT LAUNCH (this may re-run if an entity has just been scoped in)
    if !tr.autoscheduled && !entity.deny_list # manally scheuduled, automatically enrich 

      if entity.enriched
        tr.log "Re-scheduling enrichment for existing entity (manually run)!"
      end

      tr.log "Manually scheduling enrich: #{entity.name}"
      entity.enrich(tr)

    elsif tr.auto_enrich && !entity.deny_list && (!entity_already_existed || project.allow_reenrich)
      
      # Check if we've already run first and return gracefully if so
      if entity.enriched && !project.allow_reenrich
        tr.log "Skipping enrichment... already completed and re-enrich not enabled!"
      
      else

        # starts a new background task... so anything that needs to happen from
        # this point should happen in that new background task
        if entity.enriched
          tr.log "Re-scheduling enrichment for existing entity #{entity.name} (re-enrich enabled)!"
        end

        tr.log "Automatically scheduling enrich: #{entity.name}"
        entity.enrich(tr)
      end
      
    else
      tr.log "Skipping enrichment... enrich not enabled!" unless tr.auto_enrich
      tr.log "Skipping enrichment... entity #{entity.name} already exists!" if entity_already_existed
      tr.log "Skipping enrichment... entity on deny list!" if entity.deny_list
    end

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
        
        if pid < entity.alias_group_id 
          entity.alias_to(pid)

          # alias all others to the parent
          entity.aliases.each do |a|
            next if a == primary_entity || a == entity
            tr.log "Aliasing #{a.name} #{a.alias_group_id} to #{primary_entity.name}'s existing group: #{pid}"
            a.alias_to(pid)
          end

        else # Go the other way, we already had a lower id 
          primary_entity.alias_to(entity.alias_group_id)

          primary_entity.aliases.each do |a|
            next if a == primary_entity || a == entity
            tr.log "Aliasing #{a.name} #{a.alias_group_id} to #{entity.name}'s existing group: #{entity.alias_group_id}"
            a.alias_to(entity.alias_group_id)
          end

        end

      end

    end


    ### if the entity has specific scoping instructions (now that we have an entity)
    ##
    ##  the default method on the base class simply sets what was available previously
    ##  See the inidivdiual entity files for this logic.
    ##
    if scope_request
      entity.set_scoped!(scope_request.to_bool, "entity_scope_request_during_#{tr.name}")
      
      # SAVE IT
      entity.save_changes
    end

    # finally, add the new entity to our task result unless it's already there
    # OR ... we just know for a fact we dont want it (don't waste the DB query) 
    tr.add_entity(entity) unless tr.has_entity?(entity) || !entity.deny_list
      
  # return the entity with enrichment now scheduled if appropriate
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
