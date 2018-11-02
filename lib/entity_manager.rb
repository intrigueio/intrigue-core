module Intrigue
class EntityManager
  extend Intrigue::Task::Helper
  extend Intrigue::Task::Data

  # NOTE: We don't auto-register entities like the other factories (handled by
  # single table inheritance)
  def self.entity_types
    Intrigue::Model::Entity.descendants
  end

  def self.resolve_type_from_string(type_string)
    raise "INVALID TYPE TO RESOLVE: #{type_string}. DID YOU SEND A STRING? FAILING!" unless type_string.kind_of? String

    # Check full namespace first
    matches = entity_types.select{|x| x.to_s == type_string }

    # Then check all namespaces underneath
    matches.concat(entity_types.select{|x|x.to_s.split(":").last.to_s == type_string })

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

    if entity
      entity.set_details(details.to_h.deep_merge(entity.details.to_h))

      # scope it since we manually created
      entity.scoped = true
      entity.save

    else
      # Create a new entity, validating the attributes
      type = resolve_type_from_string(type_string)
      $db.transaction do
        begin
          g = Intrigue::Model::AliasGroup.create(:project_id => project.id)

          entity = Intrigue::Model::Entity.create({
            :name =>  downcased_name,
            :project => project,
            :type => type,
            :details => details,
            :hidden => false, # first entity should never be hidden - it was intentional
            :scoped => true,  # first entity should always be in scope - it was intentional
            :alias_group_id => g.id
           })

         end
      end
    end

    # necessary because of our single table inheritance?
    our_entity = Intrigue::Model::Entity.find(:id => entity.id)

    ### Ensure we have an entity
    return nil unless our_entity
    return nil unless our_entity.transform!
    return nil unless our_entity.validate_entity
    # ENRICHMENT MUST BE STARTED MANUALLY!!!!!

  our_entity
  end

  # This method creates a new entity, and kicks off a machine
  def self.create_or_merge_entity(task_result,type_string,name,details, primary_entity=nil)

    unless task_result && type_string && name && details
      task_result.log_error "Broken entity attempted: #{task_result}, #{type_string}##{name}, #{details}"
      return
    end

    # Deal with canceled tasks!
    # Do a lookup to make sure we have the latest...
    tr = Intrigue::Model::TaskResult.first(:id => task_result.id)
    if tr.cancelled
      task_result.log "Returning, task was cancelled"
      return
    end

    # Convenience
    project = task_result.project

    # Save the original and downcase our name
    details["hidden_original"] = name
    downcased_name = name.downcase

    # Merge the details if it already exists
    entity = entity_exists?(project,type_string,downcased_name)

    # check if this is actually an exception (no-traverse for this proj) entity
    no_traverse_entity = project.exception_entity?(name, type_string)
    task_result.log "Checking if #{type_string}##{name} is a no-traverse: #{no_traverse_entity}"

    # Check if there's an existing entity, if so, merge and move forward
    if entity

      entity.set_details(details.to_h.deep_merge(entity.details.to_h))

      # if it already exists, it'll have an alias group ID and we'll
      # want to use that to preserve pre-existing relatiohships
      # also... prevents an enrichment loop
      entity_already_existed = true

    else
      task_result.log_good "New Entity: #{type_string} #{name}. Scoped: #{tr.auto_scope}. No-Traverse: #{no_traverse_entity}"
      new_entity = true
      # Create a new entity, validating the attributes
      type = resolve_type_from_string(type_string)
      #$db.transaction do

        # Create a new alias group
        g = Intrigue::Model::AliasGroup.create(:project_id => project.id)

        entity_details = {
          :name => downcased_name,
          :project_id => project.id,
          :type => type.to_s,
          :details => details,
          :scoped => tr.auto_scope, # set in scope if task result auto_scope is true
          :hidden => (no_traverse_entity ? true : false ),
          :alias_group_id => g.id
        }

        begin

          # Create a new entity in that group
          entity = Intrigue::Model::Entity.update_or_create( {name: downcased_name}, entity_details)

          unless entity
            task_result.log_fatal "Unable to create entity: #{entity_details}"
            return nil
          end

        rescue Encoding::UndefinedConversionError => e
          task_result.log_fatal "Unable to create entity:#{entity_details}\n #{e}"
          return nil
        rescue Sequel::DatabaseError => e
          task_result.log_fatal "Unable to create entity:#{entity_details}\n #{e}"
          return nil
        end

      #end
    end

    # necessary to relookup?
    created_entity = Intrigue::Model::Entity.find(:id => entity.id)

    ### Ensure we have an entity
    unless created_entity
      task_result.log "ERROR! Unable to create or find entity: #{type}##{downcased_name}, failing!!"
      return nil
    end

    ### Run Data transformation (to hide attributes... HACK)
    unless created_entity.transform!
      task_result.log "ERROR! Transformation of entity failed: #{entity}, failing!!"
      return nil
    end

    ### Run Validation
    unless created_entity.validate_entity
      task_result.log "ERROR! Validation of entity failed: #{entity}, failing!!"
      return nil
    end

    # Add to our result set for this task
    task_result.add_entity created_entity
    task_result.save

    # Attach the alias.. this can be confusing....
    # ----
    # if we already had the entity, it'll already have a group it's associated with.
    # think about the case of a domain lookup where many resolve to a single
    # ip address
    if primary_entity
      task_result.log "Aliasing #{created_entity.name} to existing group: #{primary_entity.alias_group_id}"

      # Take the smaller group id, and use that to alias together
      cid = created_entity.alias_group_id
      pid = primary_entity.alias_group_id

      if cid > pid
        created_entity.alias(primary_entity)
      else
        primary_entity.alias(created_entity)
      end
    end

    # ENRICHMENT LAUNCH
    if task_result.auto_enrich && !entity_already_existed
      if !no_traverse_entity
        # Check if we've alrady run first and return gracefully if so
        if created_entity.enriched
          task_result.log "Skipping enrichment... already completed!"
        else
          task_result.log "Starting enrichment!"
          # starts a new background task... so anything that needs to happen from
          # this point should happen in that new background task
          created_entity.enrich(task_result)
        end
      else
        task_result.log "Skipping enrichment... this is a no-traverse!"
      end
    else
      task_result.log "Skipping enrichment... enrich not enabled!" unless task_result.auto_enrich
      task_result.log "Skipping enrichment... entity exists!" if entity_already_existed
    end

    #task_result.log "Created entity: #{created_entity.name}"
  # return the entity
  created_entity
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
