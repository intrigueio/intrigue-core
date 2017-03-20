module Intrigue
class EntityManager
  extend Intrigue::Task::Helper
  extend Intrigue::Task::Prohibited

  # NOTE: We don't auto-register entities like the other factories (handled by
  # single table inheritance)

  def self.resolve_type(type_string)
    # TODO - SECURITY - don't eval unless it's one of our valid entity types
    x = eval("Intrigue::Entity::#{type_string}")
    false unless x.kind_of? Intrigue::Model::Entity
  x
  end

  # This method creates a new entity, and kicks off a strategy
  def self.create_or_merge_entity(task_result,type_string,name,details)

    project = task_result.project # convenience
    downcased_name = name.downcase

    # Clean up in case there are encoding issues
    #name = _encode_string(name)
    #details = _encode_hash(details.merge(:aliases => "#{name}"]))
    type = resolve_type(type_string)

    # Merge the details if it already exists
    entity = entity_exists?(project,type,downcased_name)
    if entity
      # TODO - DEEP MERGE
      entity.details = details.deep_merge(entity.details)
      entity.save
    else
    # Create a new entity, validating the attributes
      entity = Intrigue::Model::Entity.create({
        :name =>  downcased_name,
        :project => project,
        :type => type,
        :details => details
       })
    end

    unless entity
      puts "ERROR! Unable to create or find entity: #{type}##{downcased_name}"
      return nil
    end

    unless Intrigue::Model::Entity.find(:id => entity.id).validate_entity
      puts "ERROR! validation of entity failed: #{entity}"
      return nil
    end


    # Add to our result set for this task
    task_result.add_entity entity
    task_result.save

    # Attach the aliases on both sides
    #if original_entity
      #unless Intrigue::Model::AliasMapping.where(:source_id => original_entity.id, :target_id => entity.id).first
    #  Intrigue::Model::AliasMapping.create(:source_id => original_entity.id, :target_id => entity.id)
    #  Intrigue::Model::AliasMapping.create(:source_id => entity.id, :target_id => original_entity.id)
      #end
    #end

    # START PROCESSING OF ENRICHMENT (to depth of 1)
    if task_result.depth > 0
      #unless prohibited_entity? entity
        if entity.type_string == "Host"
          start_task("task_enrichment", project, task_result.scan_result, "enrich_host", entity, 1, [],[])
        elsif entity.type_string == "Uri"
          start_task("task_autoscheduled", project, task_result.scan_result, "check_api_endpoint", entity, 1, [],[])
          start_task("task_autoscheduled", project, task_result.scan_result, "web_stack_fingerprint", entity, 1, [],[])
        end
      #end
    end# END PROCESSING OF ENRICHMENT

    #sleep 3 # give time for the enrichment to complete in case we don't have a backlog

    # START PROCESSING OF RECURSION BY STRATEGY TYPE
    scan_result = task_result.scan_result
    if scan_result  && task_result.depth > 0 # if this is a scan and we're within depth
      unless prohibited_entity? entity
        if scan_result.strategy == "discovery"
          Intrigue::Strategy::Discovery.recurse(entity, task_result)
        elsif scan_result.strategy == "web_discovery"
          Intrigue::Strategy::WebDiscovery.recurse(entity, task_result)
        end
      end
    end
    # END PROCESSING OF RECURSION BY STRATEGY TYPE

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
