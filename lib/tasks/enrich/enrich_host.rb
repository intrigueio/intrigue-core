require 'dnsruby'

module Intrigue
class EnrichHost < BaseTask

  def self.metadata
    {
      :name => "enrich_host",
      :type => "enrichment",
      :pretty_name => "Enrich Host",
      :authors => ["jcran"],
      :description => "Look up all names of a given host.",
      :references => [],
      :allowed_types => ["Host"],
      :example_entities => [{"type" => "DnsRecord", "attributes" => {"name" => "intrigue.io"}}],
      :allowed_options => [
        {:name => "resolver", :type => "String", :regex => "ip_address", :default => "8.8.8.8" },
        {:name => "record_types", :type => "String", :regex => "alpha_numeric_list", :default => "ANY" }
      ],
      :created_types => []
    }
  end

  def run
    super

    _log "Ran enrichment task!"

  end

end
end
