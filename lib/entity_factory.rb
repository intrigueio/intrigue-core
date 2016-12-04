module Intrigue
class EntityFactory
  extend Intrigue::Task::Helper

  # NOTE: We don't auto-register entities like the other factories, because they're
  # datamapper objects, and that's handled by datamapper's "type" property

  # NOTE: The user's desired depth of recursion is stored on the task_result. This
  # isn't necessarily intuitive.

  # This method creates a new entity, and kicks off a strategy
  def self.create_or_merge_entity_recursive(task_result,type_string,name,details)
      project = task_result.project # convenience

      # Clean up in case there are encoding issues
      name = _encode_string(name)
      details = _encode_hash(details)
      details.delete("name")
      type = eval("Intrigue::Entity::#{type_string}")

      # We're going to have to look for each of the aliases as well.
      entity = nil
      entity = Intrigue::Model::Entity.all(:project => project.name, :type => type).first(:name => name)

      # Merge the details if it already exists
      if entity.kind_of? Intrigue::Model::Entity
        puts "Entity exists (we may have just created it): #{entity.inspect}, merging."
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

      # Error handling... fail if we didn't save an entity
      unless entity
        _log_error "Unable to verify & save entity: #{type} #{name} #{details.inspect}"
        return false
      end

      # Link to the parent task
      puts "Entity: #{entity.inspect}"
      #puts "Entity Task Results: #{entity.task_results.count}"
      entity.add_task_result(task_result)

      # Add to our result set for this task
      task_result.add_entity entity

      # START PROCESSING OF ENRICHMENT
      if (entity.type_string == "DnsRecord")
        start_task(project, "enrich_dns_record", entity, 1, [],[])
        # TODO. this sucks. this should keep us within the scan result, and it doesn't currently.
        # so no task here will be counted as within the scan.
      end
      # END PROCESSING OF ENRICHMENT

      # START PROCESSING OF RECURSION BY STRATEGY TYPE
      if task_result.scan_result && task_result.depth > 0 # if this is a scan and we're within depth
        puts "Executing strategy against scan result: #{task_result.scan_result} at depth #{task_result.depth}"
        unless task_result.task_name =~ /enrich/ # and this isn't a one-off enrichment task
          Intrigue::Strategy::Default.recurse(entity, task_result)
        end
      else
        puts "No scan result or our depth is too deep, no recursion"
        puts "Task Result: #{task_result.inspect}"
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
