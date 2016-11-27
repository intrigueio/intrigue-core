module Intrigue
class EntityFactory
  extend Intrigue::Task::Helper

  # NOTE: We don't auto-register entities like the other factories, because they're
  # datamapper objects, and that's handled by datamapper's "type" property

  # NOTE: The user's desired depth of recursion is stored on the task_result. This
  # isn't necessarily intuitive.

  # This method creates a new entity, and kicks off a strategy
  def self.create_entity_recursive(project,task_result,type,hash)

      # Clean up in case there are encoding issues
      hash = _encode_hash(hash)
      short_name = _encode_string(hash["name"][0,199])

      # Merge the details if it already exists
      entity = Intrigue::Model::Entity.scope_by_project(project.name).first(:name => short_name)
      if entity
        entity.merge_details!(hash)
      else
        # Create the entity, validating the attributes
        entity = Intrigue::Model::Entity.create({
           :type => eval("Intrigue::Entity::#{type}"),
           :name => short_name,
           :details => hash,
           :project => project
         })
      end

      # Error handling... fail if we didn't save an entity
      unless entity
        _log_error "Unable to verify & save entity: #{type} #{hash.inspect}"
        return false
      end

      # Link to the parent task
      entity.task_results << task_result
      entity.save

      # Add to our result set for this task
      task_result.add_entity entity

      # START PROCESSING OF ENRICHMENT
      if entity.type_string == "Host"
        start_task(project, "enrich_host", entity, [],[])
      end
      # END PROCESSING OF ENRICHMENT

      # START PROCESSING OF RECURSION BY STRATEGY TYPE
      if task_result.strategy == "default"
        Intrigue::Strategy::Default.recurse(entity, task_result)
      elsif task_result.strategy == "none"
        return # no additional tasks needed
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
