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
    matches = entity_types.select{|x|x.to_s == type_string }

    # Then check all namespaces underneath
    matches.concat(entity_types.select{|x|x.to_s.split(":").last.to_s == type_string })

    #note this will be nil if we didn't match
    unless matches.first
      raise "Unable to match to a known entity. Failing."
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
            :details_raw => details,
            :hidden => false, # first entity should never be hidden - it was intentional
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

    # START ENRICHMENT
    # ENRICHMENT MUST BE STARTED MANUALLY!!!!!

  our_entity
  end

  # This method creates a new entity, and kicks off a strategy
  def self.create_or_merge_entity(task_result,type_string,name,details, primary_entity=nil)

    unless task_result && type_string && name && details
      task_result.log "ERROR! Attempting to create broken entity: #{task_result}, #{type_string}##{name}, #{details}"
    end

    # deal with canceled tasks!
    # Do a lookup to make sure we have the latest...
    tr = Intrigue::Model::TaskResult.first(:id => task_result.id)
    if tr.cancelled
      return # TODO - We should be logging here!!!
    end

    # Convenience
    project = task_result.project

    # Save the original and downcase our name
    details["hidden_original"] = name
    downcased_name = name.downcase

    # Merge the details if it already exists
    entity = entity_exists?(project,type_string,downcased_name) ## TODO - INDEX THIS!!!!!

    # check if this is actually an exception (blacklisted) entity
    # but allow anything that we've explictly set as the root (example.. facebook.com)
    if task_result.scan_result
      # always allow anything that matches our scan result's name
      if name =~  /#{task_result.scan_result.base_entity.name}/
        exception = false
      else # but if it doesn't match, just check the blacklist
        exception = project.exception_entity?(name, type_string)
      end
    else # check blacklist if we're not part of a scan
      exception = project.exception_entity?(name, type_string)
    end

    # Check if there's an existing entity, if so, merge and move forward
    if entity
      entity.set_details(details.to_h.deep_merge(entity.details.to_h))

      # if it already exists, it'll have an alias group ID and we'll
      # want to use that to preserve pre-existing relatiohships
      entity_already_existed = true

    else
      # Create a new entity, validating the attributes
      type = resolve_type_from_string(type_string)
      $db.transaction do
        begin

          entity = Intrigue::Model::Entity.create({
            :name =>  downcased_name,
            :project => project,
            :type => type,
            :details => details,
            :details_raw => details,
            :hidden => (exception ? true : false )
           })

          unless entity
            task_result.log "ERROR! Unable to create entity: #{entity}"
            return nil
          end

           g = Intrigue::Model::AliasGroup.create(:project_id => project.id)
           entity.alias_group_id = g.id
           entity.save

        rescue Encoding::UndefinedConversionError => e
          task_result.log "ERROR! Unable to create entity: #{e}"
        end
      end
    end

    # necessary because of our single table inheritance?
    # TODO - NOT NECESSARY
    created_entity = Intrigue::Model::Entity.find(:id => entity.id)

    ### Ensure we have an entity
    unless created_entity
      task_result.log "ERROR! Unable to create or find entity: #{type}##{downcased_name}, failing!!"
      return nil
    end

    ### Run Transformation
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
    #
    # if we already had the entity, it'll already have a group it's associated with.
    # think about the case of a whoisology lookup where many resolve to a single
    # ip address
    if primary_entity
      task_result.log "Aliasing #{created_entity.name} to existing group: #{primary_entity.alias_group_id}"

      #take the smaller group id, and use that to alias together
      cid = created_entity.alias_group_id
      pid = primary_entity.alias_group_id

      if cid > pid
        created_entity.alias(primary_entity)
      else
        primary_entity.alias(created_entity)
      end

    end

    # START ENRICHMENT if we're allowed and unless this entity is an exception (marked as hidden on the entity)
    if task_result.auto_enrich && !entity_already_existed
      enrich_entity(created_entity, task_result) unless exception
    end

    # START RECURSION BY STRATEGY TYPE
    if task_result.scan_result && task_result.depth > 0 # if this is a scan and we're within depth
      unless exception
        s = Intrigue::StrategyFactory.create_by_name(task_result.scan_result.strategy)
        raise "Unknown Strategy!" unless s
        s.recurse(created_entity, task_result)
      end
    end
    # END PROCESSING OF RECURSION BY STRATEGY TYPE

  # return the entity
  created_entity
  end

  def self.enrich_entity(entity, task_result)
    task_result.log  "Running enrichment on #{entity}"
    return unless entity

    # Check if we've alrady run first
    if entity.enrichment_complete?
      # TODO should we continue if we have a deeper depth!?
      task_result.log "Skipping enrichment... already completed for #{entity}!"
      return
    end

    # set depth / scan result based on the task we're passed
    scan_result = task_result.scan_result
    depth = task_result.depth

    task_result.log "Scheduling enrichment (#{entity.enrichment_tasks}) on #{entity}!"
    entity.schedule_enrichment(depth, scan_result)

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
