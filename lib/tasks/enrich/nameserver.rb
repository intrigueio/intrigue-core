module Intrigue
module Task
module Enrich
class Nameserver < Intrigue::Task::BaseTask

  include Intrigue::Task::SecurityTrails

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
    _log "Enriching... Nameserver: #{_get_entity_name}"
  end # end run()

end
end
end
end