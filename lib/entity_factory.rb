module Intrigue
class EntityFactory
  extend Intrigue::Task::Helper

  # NOTE: We don't auto-register entities like the other factories, because they're
  # datamapper objects, and that's handled by datamapper's "type" property

  # NOTE: The user's desired depth of recursion is stored on the task_result. This
  # isn't necessarily intuitive.

  # This method creates a new entity, and kicks off a strategy
  def self.create_or_merge_entity_recursive(task_result,type_string,name,details)
      project = task_result.project #convenience

      # Clean up in case there are encoding issues
      name = _encode_string(name)
      details = _encode_hash(details)
      details.delete("name")
      type = eval("Intrigue::Entity::#{type_string}")

      # We're going to have to look for each of the aliases as well.
      entity = nil
      entity = Intrigue::Model::Entity.scope_by_project_and_type(project.name, type).first(:name => name)

      # Merge the details if it already exists
      if entity.kind_of? Intrigue::Model::Entity
        puts "Got a previous entity: #{entity.inspect}, merging."
        entity.details = details.merge(entity.details)
        entity.save
      else
        # Create a new entity, validating the attributes
        entity = Intrigue::Model::Entity.create({
           :type => type,
           :name => "#{name}",
           :details => details,
           :project => project
         })
      end

      # Error handling... fail if we didn't save an entity
      unless entity
        _log_error "Unable to verify & save entity: #{type} #{name} #{details.inspect}"
        return false
      end

      # Link to the parent task
      puts "Entity: #{entity.inspect}"
      puts "Entity Task Results: #{entity.task_results}"
      entity.add_task_result(task_result)

      # Add to our result set for this task
      task_result.add_entity entity

      # START PROCESSING OF ENRICHMENT
      if (entity.type_string == "DnsRecord")
        start_task(project, "enrich_dns_record", entity, [],[])
      end
      # END PROCESSING OF ENRICHMENT

      # START PROCESSING OF RECURSION BY STRATEGY TYPE
      unless task_result.task_name =~ /enrich/
        if task_result.strategy == "default"
          Intrigue::Strategy::Default.recurse(entity, task_result)
        elsif task_result.strategy == "none"
          return # no additional tasks needed
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
