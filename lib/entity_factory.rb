module Intrigue
class EntityFactory
  extend Intrigue::Task::Helper
  extend Intrigue::Task::Prohibited

  # NOTE: We don't auto-register entities like the other factories (handled by
  # single table inheritance)

  # NOTE: The user's desired depth of recursion is stored on the task_result.

  def self.entity_exists?(type,name)
    return true if Intrigue::Model::Entity.first(:name=>name,:type=>type)
  false
  end

  def self.resolve_type(type_string)

    # TODO - SECURITY - don't eval unless it's one of our valid entity types
    x = eval("Intrigue::Entity::#{type_string}")
    false unless x.kind_of? Intrigue::Model::Entity
  x
  end

  # This method creates a new entity, and kicks off a strategy
  def self.create_or_merge_entity_recursive(task_result,type_string,name,details, original_entity)

    project = task_result.project # convenience

    # Clean up in case there are encoding issues
    name = _encode_string(name)
    details = _encode_hash(details)
    #details.delete("name")

    type = resolve_type(type_string)

    # Merge the details if it already exists
    entity = nil
    entity = Intrigue::Model::Entity.scope_by_project_and_type(project.name,type).first(:name => name)

    # We're going to have to look for each of the aliases as well.
    if entity.kind_of? Intrigue::Model::Entity
      entity.details = details.merge(entity.details)
      entity.save
    else
    # Create a new entity, validating the attributes
      entity = Intrigue::Model::Entity.create({
        :project => project,
        :type => type,
        :name => "#{name}",
        :details => details
       })
    end

    unless entity
      puts "ERROR! Unable to create entity: #{type}##{name}"
      return nil
    end

    # Add to our result set for this task
    task_result.add_entity entity
    task_result.save

    # Attach the aliases on both sides
    if original_entity
      #unless Intrigue::Model::AliasMapping.where(:source_id => original_entity.id, :target_id => entity.id).first
      Intrigue::Model::AliasMapping.create(:source_id => original_entity.id, :target_id => entity.id)
      Intrigue::Model::AliasMapping.create(:source_id => entity.id, :target_id => original_entity.id)
      #end
    end

    # START PROCESSING OF ENRICHMENT (to depth of 1)
    if task_result.depth > 0
      if (entity.type_string == "Uri")
        unless prohibited_entity? entity
          start_task("task_autoscheduled", project, task_result.scan_result, "check_api_endpoint", entity, 1, [],[])
          start_task("task_autoscheduled", project, task_result.scan_result, "web_stack_fingerprint", entity, 1, [],[])
        end
      end
    end# END PROCESSING OF ENRICHMENT

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
