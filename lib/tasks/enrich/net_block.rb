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

    # return if we've already enriched in a whois task
    return if _get_entity_detail "whois_full_text"

    netblock_string = _get_entity_name
    lookup_string = _get_entity_name.split("/").first
    out = whois lookup_string

    if out["whois_full_text"] =~ /RIPE/
      out = whois_rir_ip "RIPE", lookup_string, out
    elsif out["whois_full_text"] =~ /ARIN/
      out = whois_rir_ip "ARIN", lookup_string, out
    else
      _log_error "Unknown RIR, failing"
    end

    # make sure not to overwrite the name in the details
    out = out.merge({"name" => netblock_string, "_hidden_name" => netblock_string})

    # lazy but easier than setting invidually
    _log "Setting entity details to... #{out}"
    _set_entity_details out

  end

end
end
end
