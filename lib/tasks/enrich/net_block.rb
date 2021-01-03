module Intrigue
module Task
module Enrich
class NetBlock < Intrigue::Task::BaseTask

  include Intrigue::Task::Whois

  def self.metadata
    {
      :name => "enrich/net_block",
      :pretty_name => "Enrich NetBlock",
      :authors => ["jcran"],
      :description => "Fills in details for a NetBlock",
      :references => [],
      :type => "enrichment",
      :passive => true,
      :allowed_types => ["NetBlock"],
      :example_entities => [{"type" => "NetBlock", "details" => {"name" => "10.0.0.0/24"}}],
      :allowed_options => [],
      :created_types => []
    }
  end

  def run

    netblock_string = _get_entity_name
    lookup_string = _get_entity_name.split("/").first
    cidr_string = _get_entity_name.split("/").last

    if _get_entity_detail "whois_full_text" # skip lookup if we already have it
      _log "Skipping lookup, we already have the details"
      out = @entity.details
    else # do the lookup
      out = whois(lookup_string)
      if out 
        # make sure not to overwrite the name in the details
        netblock_hash = out.first.merge({"name" => netblock_string, "_hidden_name" => netblock_string})
        # lazy but easier than setting invidually
        _log "Setting entity details to... #{netblock_hash}"
        _get_and_set_entity_details netblock_hash
      end
    end


    ###
    ### Find related netblock via whois
    ###
    whois_text = _get_entity_detail("whois_full_text")
    if whois_text
      # okay now, let's check to see if there's a reference to a more specific block here
      netblock_regex = /(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}\/(\d{1,2}))/
      match_captures = whois_text.scan(netblock_regex)
      match_captures.each do |capture|
        # create it 
        netblock = capture.first
        _log "Found related netblock: #{netblock}"
        _create_entity "NetBlock", { "name" => "#{netblock}" }
      end

      # check transferred
      if whois_text.match /Early Registrations, Transferred to/
        _set_entity_detail "transferred", true
      end
    end

    # check ipv6
    if _get_entity_name.match /::/
      _set_entity_detail "ipv6", true
    end

    ###
    ### Clean up org name ... some examples:
    ###

    #org-name:       Acme Sciences, Inc.      
    #Organization:   Acme sciences (ACME-3)\n
    #Organization:   Confluence Networks Inc (CN)
    #Organization:   CyrusOne LLC (CL-260)
    #Organization:   Rackspace Hosting (RACKS-8)
    existing_org_name = _get_entity_detail("organization_name")
    unless existing_org_name && existing_org_name.length >  0 
   
      org_name = nil
      org_regex = /org-name:.*$/i
      match_captures = "#{whois_text}".scan(org_regex)
      org_name = match_captures.last

      unless org_name
        org_regex = /Customer:.*$/i
        match_captures = "#{whois_text}".scan(org_regex)
        org_name = match_captures.last  
      end

      unless org_name
        org_regex = /Organization:.*$/i
        match_captures = "#{whois_text}".scan(org_regex)
        org_name = match_captures.last  
      end

      unless org_name
        org_regex = /descr:.*$/i
        match_captures = "#{whois_text}".scan(org_regex)
        org_name = match_captures.last  
      end
      
      if org_name
        clean_org_name = "#{org_name}".split(":").last.strip
        _set_entity_detail("organization_name", clean_org_name) 
      end

    end

  end

end
end
end
end