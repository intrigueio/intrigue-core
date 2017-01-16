module Intrigue
class EntityFactory
  extend Intrigue::Task::Helper

  # NOTE: We don't auto-register entities like the other factories, because they're
  # datamapper objects, and that's handled by datamapper's "type" property

  # NOTE: The user's desired depth of recursion is stored on the task_result. This
  # isn't necessarily intuitive.

  def self.entity_exists?(type,name)
    return true if Intrigue::Model::Entity.first(:name=>name,:type=>type)
  false
  end

  # This method creates a new entity, and kicks off a strategy
  def self.create_or_merge_entity_recursive(task_result,type_string,name,details, original_entity)

    project = task_result.project # convenience

    # Clean up in case there are encoding issues
    name = _encode_string(name)
    details = _encode_hash(details)
    details.delete("name")
    type = eval("Intrigue::Entity::#{type_string}")

    # We're going to have to look for each of the aliases as well.
    entity = nil
    entity = Intrigue::Model::Entity.scope_by_project_and_type(project.name,type).first(:name => name)

    # Merge the details if it already exists
    if entity.kind_of? Intrigue::Model::Entity
      #puts "Entity exists: #{entity.inspect}, merging."
      entity.details = details.merge(entity.details)
      entity.save
    else
      # Create a new entity, validating the attributes
      begin
        entity = Intrigue::Model::Entity.create({
          :project => project,
          :type => type,
          :name => "#{name}",
          :details => details
         })

        if original_entity
          entity.secondary=true;
          entity.save
        end
      rescue DataMapper::SaveFailureError => e
        return false
      end

    end

    # Error handling... fail if we didn't save an entity
    unless entity
      return false
    end

    # Add to our result set for this task
    task_result.add_entity entity
    task_result.save

    # START PROCESSING OF ENRICHMENT (to depth of 1)
    if task_result.depth > 0
      if (entity.type_string == "Uri")
        start_task("task_autoscheduled", project, task_result.scan_result, "web_server_fingerprint", entity, task_result.depth, [],[])
        start_task("task_autoscheduled", project, task_result.scan_result, "web_application_fingerprint", entity, task_result.depth, [],[])
      end
    end# END PROCESSING OF ENRICHMENT

    # START PROCESSING OF RECURSION BY STRATEGY TYPE
    if task_result.scan_result && task_result.depth > 0 # if this is a scan and we're within depth
      Intrigue::Strategy::Default.recurse(entity, task_result)
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
