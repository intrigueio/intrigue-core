require 'resolv'

module Intrigue
module Task
class SearchQuad9DnS < BaseTask

  def self.metadata
    {
      :name => "search_quad9_dns",
      :pretty_name => "Search Quad9 DNS",
      :authors => ["Anas Ben Salah"],
      :description => "This task looks up whether hosts are blocked by Quad9 DNS (9.9.9.9)",
      :references => ["https://www.quad9.net"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain"],
      :example_entities => [{"type" => "Domain", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => []
    }
  end


  ## Default method, subclasses must override this
  def run
    super
    res = []
    entity_name = _get_entity_name

    # Query quad9 nameservers
    nameservers = ['9.9.9.9']
    _log "Querying #{nameservers}"
    dns_obj = Resolv::DNS.new(nameserver: nameservers)
    res = dns_obj.getaddresses(entity_name)

    # Detected only if there's no resolution
    if res.any?
      _log "Resolves to #{res.map{|x| "#{x.to_name}" }}. Seems we're good!"
    else
      _malicious_entity_detected("Quad9") 
    end

  end #end run


end
end
end
