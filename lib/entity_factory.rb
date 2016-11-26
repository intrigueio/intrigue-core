module Intrigue
class EntityFactory

  # NOTE: We don't auto-register entities like the other factories, because they're
  # datamapper objects, and that's handled for us

  # This method creates a new entity, and kicks off a strategy
  def self.create_entity_recursive(project,task_result,type,hash)

      # Clean up in case there are encoding issues
      hash = _encode_hash(hash)

      short_name = _encode_string(hash["name"][0,199])
      entity = Intrigue::Model::Entity.scope_by_project(project.name).first(:name => short_name)

      # Merge the details if it already exists
      if entity
        entity.details = entity.details.merge(hash)
        entity.save
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

      # START PROESSING OF FOLLOW-ON TASKS BY STRATEGY
      if task_result.strategy == "default"
        Intrigue::Strategy::Default.recurse(entity, task_result)
      elsif task_result.strategy == "interactive"
        return # no additional tasks needed
      end
      # /END PROCESSING OF FOLLOW-ON TASKS

    # return the entity
    entity
  end

  private

  ###
  ### Helpers for handling encoding
  ###

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
