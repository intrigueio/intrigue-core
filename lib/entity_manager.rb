module Intrigue
class EntityManager
  extend Intrigue::Task::Helper
  extend Intrigue::Task::Prohibited

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

  # This method creates a new entity, and kicks off a strategy
  def self.create_or_merge_entity(task_result,type_string,name,details, primary_entity=nil)

    project = task_result.project # convenience
    downcased_name = name.downcase

    # Merge the details if it already exists
    entity = entity_exists?(project,type_string,downcased_name)

    # check if there's an existing entity, if so, merge and move forward
    if entity
      entity.details = details.deep_merge(entity.details)
      entity.save
    else
      # Create a new entity, validating the attributes
      type = resolve_type(type_string)
      $db.transaction do
        entity = Intrigue::Model::Entity.create({
          :name =>  downcased_name,
          :project => project,
          :type => type,
          :details => details
         })
      end
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
    if primary_entity
      self.alias_entity primary_entity, entity
      self.alias_entity entity, primary_entity
    end

    # START PROCESSING OF ENRICHMENT (to depth of 1)
    enrich_entity entity, task_result

    # START RECURSION BY STRATEGY TYPE
    if task_result.scan_result && task_result.depth > 0 # if this is a scan and we're within depth
      unless prohibited_entity? entity
        if task_result.scan_result.strategy == "discovery"
          Intrigue::Strategy::Discovery.recurse(entity, task_result)
        elsif task_result.scan_result.strategy == "web_discovery"
          Intrigue::Strategy::WebDiscovery.recurse(entity, task_result)
        end
      end
    end
    # END PROCESSING OF RECURSION BY STRATEGY TYPE

  # return the entity
  entity
  end

  def self.enrich_entity(entity, task_result=nil)
    puts  "STARTING enrichment on #{entity}"
    return unless entity

    # Check if we've alrady run first
    if entity.details["enriched"]
      puts "SKIPPING Enrichment already happened for #{entity}!"
      return
    end

    scan_result = task_result.scan_result if task_result

    # Enrich by type
    if entity.type_string == "DnsRecord"
      start_task("task_enrichment", entity.project, scan_result, "enrich_dns_record", entity, 1, [],[])
    elsif entity.type_string == "IpAddress"
      start_task("task_enrichment", entity.project, scan_result, "enrich_ip_address", entity, 1, [],[])
    elsif entity.type_string == "Uri"
      start_task("task_autoscheduled", entity.project, scan_result, "enrich_uri", entity, 1, [],[])
      start_task("task_autoscheduled", entity.project, scan_result, "web_stack_fingerprint", entity, 1, [],[])
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
