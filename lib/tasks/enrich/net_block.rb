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
      out = whois(lookup_string) || {}
      # make sure not to overwrite the name in the details
      out = out.merge({"name" => netblock_string, "_hidden_name" => netblock_string})
      # lazy but easier than setting invidually
      _log "Setting entity details to... #{out}"
      _set_entity_details out
    end


    ###
    ### Find related netblock via whois
    ###

    # okay now, let's check to see if there's a reference to a more specific block here
    netblock_regex = /(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}\/(\d{1,2}))/
    whois_text = _get_entity_detail("whois_full_text")
    match_captures = whois_text.scan(netblock_regex)
    match_captures.each do |capture|
      # create it 
      netblock = capture.first
      _log "Found related netblock: #{netblock}"
      _create_entity "NetBlock", "name" => "#{netblock}"
    end

    # check transferred
    if out["whois_full_text"] =~ /Early Registrations, Transferred to/
      _set_entity_detail "transferred", true
    end

    # check ipv6
    if _get_entity_name =~ /::/
      _set_entity_detail "ipv6", true
    end

  end

end
end
end
end