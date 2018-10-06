module Intrigue
module Task
class EnrichNetBlock < BaseTask

  include Intrigue::Task::Whois

  def self.metadata
    {
      :name => "enrich/net_block",
      :pretty_name => "Enrich NetBlock",
      :authors => ["jcran"],
      :description => "Fills in details for a NetBlock",
      :references => [],
      :type => "enrichment",
      :passive => false,
      :allowed_types => ["NetBlock"],
      :example_entities => [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
      :allowed_options => [],
      :created_types => []
    }
  end

  def run
    super

    netblock_string = _get_entity_name
    lookup_string = _get_entity_name.split("/").first

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

    # check transferred
    if out["whois_full_text"] =~ /Early Registrations, Transferred to/
      _set_entity_detail "transferred", true
    end

    # check ipv6
    if _get_entity_name =~ /::/
      _set_entity_detail "ipv6", true
    end

    ### Determine if scoped
    @entity.project.entities.where(:scoped => true).each do |e|
      if out["whois_full_text"] =~ /#{e.name}/
        _log "In scope based on #{e.name} whitelisted entity"
        @entity.scoped = true
        @entity.save
      end
    end

    if @entity.created_by?("search_bgp")
      _log "In scope because we were created by search_bgp"
      @entity.scoped = true
      @entity.save
    end

  end

end
end
end
