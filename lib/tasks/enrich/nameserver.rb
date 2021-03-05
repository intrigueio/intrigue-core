module Intrigue
module Task
module Enrich
class Nameserver < Intrigue::Task::BaseTask

  def self.metadata
    {
      :name => "enrich/nameserver",
      :pretty_name => "Enrich Nameserver",
      :authors => ["jcran"],
      :description => "Enrich a nameserver entity",
      :references => [],
      :allowed_types => ["Nameserver"],
      :type => "enrichment",
      :passive => true,
      :example_entities => [{"type" => "Nameserver", "details" => {"name" => "ns1.intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["Domain"]
    }
  end

  def run
    super
    
    lookup_name = _get_entity_name
    _log "Enriching... Nameserver: #{lookup_name}"

    # Do a lookup
    _log "Resolving: #{lookup_name}"
    results = resolve(lookup_name)

    _log "Grabbing resolutions"
    resolutions = collect_resolutions(results)

    _set_entity_detail("resolutions", resolutions)

  end # end run

end
end
end
end