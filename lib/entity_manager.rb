module Intrigue
class EntityManager
  extend Intrigue::Task::Helper
  extend Intrigue::Task::Data

  # NOTE: We don't auto-register entities like the other factories (handled by
  # single table inheritance)
  def self.entity_types
    Intrigue::Model::Entity.descendants
  end

  def self.resolve_type(type_string)
    raise "INVALID TYPE TO RESOLVE: #{type_string}. DID YOU SEND A STRING?" unless type_string.kind_of? String

    # Don't eval unless it's one of our valid entity type
    if type_string =~ /:/
      return eval("#{type_string}") if entity_types.map{|x|x.to_s}.include? "#{type_string}"
    else
      return eval("Intrigue::Entity::#{type_string}") if entity_types.map{|x|x.to_s}.include? "Intrigue::Entity::#{type_string}"
    end

  false
  end

  def self.alias_entity(s,t)
    unless Intrigue::Model::AliasMapping.first(:source_id => s.id, :target_id => t.id)
      Intrigue::Model::AliasMapping.create(:source_id => s.id, :target_id => t.id)
      Intrigue::Model::AliasMapping.create(:source_id => t.id, :target_id => s.id)
    end
  end

  def self.create_first_entity(project_name,type_string,name,details)

    # Save the original and downcase our name
    details["hidden_original"] = name
    downcased_name = name.downcase

    # Try to find our project and create it if it doesn't exist
    project = Intrigue::Model::Project.first(:name => project_name)
    project = Intrigue::Model::Project.create(:name => project_name) unless project

    # Merge the details if it already exists
    entity = entity_exists?(project,type_string,downcased_name)
    hidden = hidden_entity?(name, type_string)

    if entity
      entity.set_details(details.to_h.deep_merge(entity.details.to_h))
    else
      # Create a new entity, validating the attributes
      type = resolve_type(type_string)
      $db.transaction do
        begin
          entity = Intrigue::Model::Entity.create({
            :name =>  downcased_name,
            :project => project,
            :type => type,
            :details => details,
            :details_raw => details,
            :hidden => (hidden ? true : false )
           })
         rescue Encoding::UndefinedConversionError => e
           task_result.log "ERROR! Unable to create entity: #{e}"
         end
      end
    end

    # necessary because of our single table inheritance?
    created_entity = Intrigue::Model::Entity.find(:id => entity.id)

    ### Ensure we have an entity
    return nil unless created_entity
    return nil unless created_entity.transform!
    return nil unless created_entity.validate_entity

  created_entity
  end

  # This method creates a new entity, and kicks off a strategy
  def self.create_or_merge_entity(task_result,type_string,name,details, primary_entity=nil)

    unless task_result && type_string && name && details
      task_result.log "ERROR! Attempting to create broken entity: : #{task_result}, #{type_string}##{name}, #{details}"
    end

    # HANDLE CANCELED TASKS!
    # Do a lookup to make sure we have the latest...
    tr = Intrigue::Model::TaskResult.first(:id => task_result.id)
    if tr.cancelled
      # We should try logging here!!!
      return
    end

    # Convenience
    project = task_result.project

    # Save the original and downcase our name
    details["hidden_original"] = name
    downcased_name = name.downcase


    # Merge the details if it already exists
    entity = entity_exists?(project,type_string,downcased_name)
    hidden = hidden_entity?(name, type_string)

    # Check if there's an existing entity, if so, merge and move forward
    if entity
      entity.set_details(details.to_h.deep_merge(entity.details.to_h))
    else
      # Create a new entity, validating the attributes
      type = resolve_type(type_string)
      $db.transaction do
        begin
          entity = Intrigue::Model::Entity.create({
            :name =>  downcased_name,
            :project => project,
            :type => type,
            :details => details,
            :details_raw => details,
            :hidden => (hidden ? true : false )
           })
        rescue Encoding::UndefinedConversionError => e
          task_result.log "ERROR! Unable to create entity: #{e}"
        end
      end
    end

    # necessary because of our single table inheritance?
    created_entity = Intrigue::Model::Entity.find(:id => entity.id)

    ### Ensure we have an entity
    unless created_entity
      task_result.log "ERROR! Unable to create or find entity: #{type}##{downcased_name}"
      #return nil
    end

    ### Run Transformation
    unless created_entity.transform!
      task_result.log "ERROR! Transformation of entity failed: #{entity}"
      #return nil
    end

    ### Run Validation
    unless created_entity.validate_entity
      task_result.log "ERROR! Validation of entity failed: #{entity}"
      #return nil
    end


    # Add to our result set for this task
    task_result.add_entity created_entity
    task_result.save

    # Attach the aliases on both sides
    if primary_entity
      self.alias_entity primary_entity, created_entity
      self.alias_entity created_entity, primary_entity
    end

    # START ENRICHMENT if we're allowed and unless this entity is prohibited (hidden)
    task_result.log "Entity Enrichment: #{task_result.auto_enrich}"
    task_result.log "Entity Hidden: #{hidden}"
    if task_result.auto_enrich
      enrich_entity(created_entity, task_result) unless hidden
    end

    # START SIGNAL ANALYSIS
    #Intrigue::Signals.all.each{|s| x = s.new(entity,task_result); x.generate if x.match }

    # START RECURSION BY STRATEGY TYPE
    if task_result.scan_result && task_result.depth > 0 # if this is a scan and we're within depth
      unless hidden
        s = Intrigue::StrategyFactory.create_by_name(task_result.scan_result.strategy)
        raise "Unknown strategy!?!?!" unless s
        s.recurse(created_entity, task_result)
      end
    end
    # END PROCESSING OF RECURSION BY STRATEGY TYPE

  # return the entity
  created_entity
  end

  def self.enrich_entity(entity, task_result=nil)

    task_result.log  "Running enrichment on #{entity}" if task_result
    return unless entity

    # Check if we've alrady run first
    if entity.enriched
      task_result.log "Skipping enrichment... already happened for #{entity}!" if task_result
      return
    end

    # set depth / scan result based on the task we're passed
    if task_result
      scan_result = task_result.scan_result
      depth = task_result.depth
    else
      depth = 1
    end

    # Enrich by type
    if entity.type_string == "DnsRecord"
      start_task("task_enrichment", entity.project, scan_result, "enrich_dns_record", entity, depth, [],[])
    elsif entity.type_string == "IpAddress"
      start_task("task_enrichment", entity.project, scan_result, "enrich_ip_address", entity, depth, [],[])
    elsif entity.type_string == "Uri"
      start_task("task_enrichment", entity.project, scan_result, "enrich_uri", entity, depth, [],[])
      start_task("task_enrichment", entity.project, scan_result, "web_stack_fingerprint", entity, depth, [],[])
    end

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
