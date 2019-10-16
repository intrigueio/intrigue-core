module Intrigue
class EntityManager
  extend Intrigue::Task::Helper
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
      $db.transaction do
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
  def self.create_or_merge_entity(task_result,type_string,name,details,primary_entity=nil)

    unless task_result && type_string && name && details
      task_result.log_error "Broken entity attempted: #{task_result}, #{type_string}##{name}, #{details}"
      return
    end

    # Deal with canceled tasks and deleted projects!
    # Do a lookup to make sure we have the latest...
    tr = Intrigue::Model::TaskResult.first(:id => task_result.id)
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

    # Merge the details if it already exists
    entity = entity_exists?(project,type_string,downcased_name)

    # find exception regexes we can skip (if they're a seed or an ancestor)
    skip_regexes = []

    # check seeds
    project.seeds.each do |s|
      seed_type_string = s.type.to_s.split(":").last
      
      # IpAddresses can't be used to skip, since they mess up netblocks
      next if seed_type_string == "IpAddress"  # TOOD.. this should really be a global list (see: netblock scoping)

      # check if the seed matches a non-traversable entity
      r = project.standard_exception?(s.name, seed_type_string)

      # okay so if a seed is in the standard list we can prevent it from becoming an eception
      skip_regexes << r if r
    end

    # simplify so we dont end up with a bunch of dupes
    skip_regexes = skip_regexes.uniq.compact
    #tr.log "Got Skip Regexes: #{skip_regexes}"

    if skip_regexes.count > 0
      tr.log "This no-traverse regex will be bypassed since it matches a seed: #{skip_regexes}"
    end

    # check if this is actually a provided exception (no-traverse for this proj) entity
    exception_pattern = project.exception_entity?(name, type_string, skip_regexes)

    # Check if there's an existing entity, if so, merge and move forward
    if entity
      tr.log_good "Existing Entity: #{type_string} #{name}. No-Traverse: #{exception_pattern}"
      
      entity.set_details(details.to_h.deep_merge(entity.details.to_h))

      # if it already exists, it'll have an alias group ID and we'll
      # want to use that to preserve pre-existing relatiohships
      # also... prevents an enrichment loop
      entity_already_existed = true

    else
      tr.log_good "New Entity: #{type_string} #{name}. No-Traverse: #{exception_pattern}"

      # Create a new entity, validating the attributes
      type = resolve_type_from_string(type_string)
      $db.transaction do

        # Create a new alias group
        g = Intrigue::Model::AliasGroup.create(:project_id => project.id)

        entity_details = {
          :name => downcased_name,
          :project_id => project.id,
          :type => type.to_s,
          :details => details,
          :hidden => (exception_pattern ? true : false ),
          :alias_group_id => g.id
        }

        #####
        ### HANDLE USER- or TASK- PROVIDED SCOPING 
        #####

        # if we're told this thing is scoped, let's just mark it scoped
        # note that we delete the detail since we no longer need it 
        # TODO... is this used today?
        if (details["scoped"] == true || details["unscoped"] == "true")
          tr.log "Entity was specifically requested to be scoped"
          details = details.tap { |h| h.delete("scoped") }
          entity_details[:scoped] = true
        
        # otherwise ____ default to unscoped ___ 
        # note that we delete the detail since we no longer need it 
        elsif (details["unscoped"] == true || details["unscoped"] == "true")
          tr.log "Entity was specifically requested to be unscoped"
          details = details.tap { |h| h.delete("unscoped") }
          entity_details[:scoped] = false
        
        # if it's set, rely on the task result's auto_scope setting 
        # - which is set when the entity is created, based on context 
        # that is (or at least should be) specific to that task
        elsif tr.auto_scope
          tr.log "Task result scoped this entity based on auto_scope"
          entity_details[:scoped] = true
        
        # otherwise, fall back to false
        else
          tr.log "No specific scope request, asking entity rules!"
          entity_details[:scoped] = true
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

      end
    end

    # necessary to relookup?
    entity = Intrigue::Model::Entity.find(:id => entity.id)

    ### Ensure we have an entity
    unless entity
      tr.log_error "Unable to create or find entity: #{type}##{downcased_name}, failing!!"
      return nil
    end

    ### Run Data transformation (to hide attributes... HACK)
    unless entity.transform!
      tr.log_error "Transformation of entity failed: #{entity}, failing!!"
      return nil
    end

    ### Run Validation
    unless entity.validate_entity
      tr.log_error "Validation of entity failed: #{entity}, failing!!"
      return nil
    end

    # Add to our result set for this task
    tr.add_entity entity

    # Attach the alias.. this can be confusing....
    # ----
    # if we already had the entity, it'll already have a group it's associated with.
    # think about the case of a domain lookup where many resolve to a single
    # ip address
    if primary_entity
      
      tr.log "Aliasing #{entity.name} to existing group: #{primary_entity.alias_group_id}"

      # Take the smaller group id, and use that to alias together
      cid = entity.alias_group_id
      pid = primary_entity.alias_group_id
      cid > pid ? entity.alias_to(pid) : primary_entity.alias_to(cid)

    end

    ## Now, if we're still scoped, set the scoping based on entity rules
    if entity.scoped
      
      entity.scoped = entity.scoped?
      entity.save_changes

      tr.log "Entity was scoped by task process, so we set scoped based on entity rules: #{entity.scoped}"
    end


    # ENRICHMENT LAUNCH
    if tr.auto_enrich && !entity_already_existed
      if !exception_pattern
        # Check if we've alrady run first and return gracefully if so
        if entity.enriched
          tr.log "Skipping enrichment... already completed!"
        else
          # starts a new background task... so anything that needs to happen from
          # this point should happen in that new background task
          entity.enrich(tr)
        end
      else
        tr.log "Skipping enrichment... this is a no-traverse!"
      end
    else
      tr.log "Skipping enrichment... enrich not enabled!" unless tr.auto_enrich
      tr.log "Skipping enrichment... entity exists!" if entity_already_existed
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
